#!/usr/bin/env bash
# Safe product demo: all meeting-changing calls go to the loopback mock.

set -euo pipefail

DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$DEMO_DIR/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
PORT_FILE="$TEMP_DIR/port"

cleanup() {
  if [[ -n "${SERVER_PID:-}" ]]; then
    kill "$SERVER_PID" 2>/dev/null || true
  fi
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT HUP INT TERM

say() {
  printf '\n\033[1;36m%s\033[0m\n' "$1"
}

say "1. Validate the distributable plugin"
bash "$PLUGIN_DIR/tests/validate_package.sh"
jq '{name, version, license}' "$PLUGIN_DIR/plugin.json"
jq '.mcpServers.meetstream | {type, url, auth: .headers.Authorization}' "$PLUGIN_DIR/mcp.json"

say "2. Start the loopback-only MeetStream fixture"
python3 "$PLUGIN_DIR/tests/mock_server.py" 0 "$PORT_FILE" &
SERVER_PID=$!
for _ in {1..50}; do
  [[ -s "$PORT_FILE" ]] && break
  sleep 0.1
done
[[ -s "$PORT_FILE" ]] || { echo "mock server failed to start" >&2; exit 1; }

MEETSTREAM_API_BASE="http://127.0.0.1:$(<"$PORT_FILE")/api/v1"
export MEETSTREAM_API_BASE
export MEETSTREAM_TEST_MODE=1
export MEETSTREAM_API_KEY=test-key

say '3. “Show the MIA agents I can use”'
"$PLUGIN_DIR/scripts/list-agents.sh"

say '4. “Send my standup agent to this meeting” (mock only)'
"$PLUGIN_DIR/scripts/send-bot.sh" \
  --link "https://meet.google.com/abc-defg-hij" \
  --name "Standup Bot" \
  --agent-name "standup"

say '5. “Remove the bot from the current call” fails closed when ambiguous'
set +e
"$PLUGIN_DIR/scripts/remove-bot.sh" --current
remove_status=$?
set -e
if [[ "$remove_status" -eq 0 ]]; then
  echo "unexpected success: ambiguity guard did not trigger" >&2
  exit 1
fi
echo "PASS: no bot was guessed or removed"

say "Demo complete — no production meeting or credential was used"
