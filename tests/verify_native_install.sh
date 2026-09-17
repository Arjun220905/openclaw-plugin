#!/usr/bin/env bash
# Build a clean archive and prove OpenClaw recognizes and loads its native
# manifest/runtime. This uses an isolated OpenClaw state directory and never
# calls MeetStream or requires a MeetStream API key.
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$TEST_DIR/.." && pwd)"
PACK_DIR="$(mktemp -d)"
STATE_DIR="$(mktemp -d)"
trap 'rm -rf "$PACK_DIR" "$STATE_DIR"' EXIT HUP INT TERM

command -v openclaw >/dev/null 2>&1 || {
  echo "error: OpenClaw must be installed to verify native runtime loading" >&2
  exit 69
}
command -v jq >/dev/null 2>&1 || {
  echo "error: jq is required" >&2
  exit 69
}

archive_name="$(npm pack --pack-destination "$PACK_DIR" --silent --prefix "$PLUGIN_DIR")"
archive_path="$PACK_DIR/$archive_name"

OPENCLAW_STATE_DIR="$STATE_DIR" openclaw plugins install "$archive_path" \
  --force --accept-capabilities --acknowledge-install-policy-warning >/dev/null

inspection="$(OPENCLAW_STATE_DIR="$STATE_DIR" openclaw plugins inspect openclaw-x-meetstream-skill --runtime --json)"
jq -e '
  .plugin.format == "openclaw" and
  .plugin.status == "loaded" and
  .plugin.version == "1.1.0" and
  .plugin.mcpServers.meetstream.transport == "streamable-http" and
  .plugin.mcpServers.meetstream.workingDirectory == "." and
  (.plugin.mcpServers.meetstream | has("cwd") | not) and
  (.mcpServers | map(.name) | index("meetstream")) != null and
  (.plugin.diagnostics // [] | length) == 0
' >/dev/null <<<"$inspection"

skills="$(OPENCLAW_STATE_DIR="$STATE_DIR" openclaw skills list --json)"
for name in meetstream meetstream-bot-builder meetstream-calendar meetstream-debugger meetstream-notetaker; do
  jq -e --arg name "$name" '.skills[] | select(.name == $name and .eligible == true)' \
    >/dev/null <<<"$skills"
done

echo "PASS: clean archive installs as a native OpenClaw plugin with its MCP server and five eligible skills"
