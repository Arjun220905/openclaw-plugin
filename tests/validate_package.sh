#!/usr/bin/env bash
# Validate the distributable Agent Plugin without contacting MeetStream.

set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$TEST_DIR/.." && pwd)"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

command -v jq >/dev/null 2>&1 || fail "jq is required"

jq -e '
  .id == "openclaw-x-meetstream-skill" and
  .version == "1.1.0" and
  (.name | type == "string" and length > 0) and
  (.description | type == "string" and length > 0) and
  .configSchema.type == "object" and
  .configSchema.additionalProperties == false and
  .configSchema.properties == {} and
  .skills == ["skills"] and
  .mcpServers.meetstream.url == "https://mcp.meetstream.ai/mcp" and
  .mcpServers.meetstream.transport == "streamable-http" and
  .mcpServers.meetstream.workingDirectory == "." and
  (.mcpServers.meetstream | has("cwd") | not) and
  .mcpServers.meetstream.headers.Authorization == "Bearer ${MEETSTREAM_API_KEY}"
' "$PLUGIN_DIR/openclaw.plugin.json" >/dev/null || fail "openclaw.plugin.json does not match the native plugin contract"

jq -e '
  ."$schema" == "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json" and
  .name == "openclaw-x-meetstream-skill" and
  .version == "1.1.0" and
  .license == "MIT" and
  .repository == "https://github.com/meetstream-ai/openclaw-plugin"
' "$PLUGIN_DIR/plugin.json" >/dev/null || fail "plugin.json no longer provides valid Agent Plugin compatibility metadata"

jq -e '
  .name == "openclaw-x-meetstream-skill" and
  .version == "1.1.0" and
  .license == "MIT" and
  .repository.url == "https://github.com/meetstream-ai/openclaw-plugin.git" and
  .type == "module" and
  .engines.node == ">=22" and
  (has("dependencies") | not) and
  (has("devDependencies") | not) and
  .peerDependencies.openclaw == ">=2026.9.1 <2027.0.0" and
  .openclaw.extensions == ["./index.js"] and
  .openclaw.compat.pluginApi == ">=2026.9.1 <2027.0.0" and
  .openclaw.compat.minGatewayVersion == "2026.9.1" and
  .openclaw.build.openclawVersion == "2026.9.1" and
  .openclaw.build.pluginSdkVersion == "2026.9.1"
' "$PLUGIN_DIR/package.json" >/dev/null || fail "package.json does not declare a compatible native OpenClaw runtime"

[[ -f "$PLUGIN_DIR/index.js" ]] || fail "native runtime entry index.js is missing"
node --check "$PLUGIN_DIR/index.js" >/dev/null || fail "native runtime entry does not parse"

jq -e '
  ."$schema" == "https://agent-plugins.org/schemas/1.0.0/mcp.schema.json" and
  (keys | sort) == ["$schema","mcpServers"] and
  (.mcpServers | keys) == ["meetstream"] and
  .mcpServers.meetstream.type == "streamable-http" and
  .mcpServers.meetstream.url == "https://mcp.meetstream.ai/mcp" and
  .mcpServers.meetstream.headers.Authorization == "Bearer ${MEETSTREAM_API_KEY}"
' "$PLUGIN_DIR/mcp.json" >/dev/null || fail "mcp.json destination, transport, or per-request auth is incorrect"

jq -e '
  (keys | sort) == ["mcpServers"] and
  .mcpServers.meetstream.type == "http" and
  .mcpServers.meetstream.url == "https://mcp.meetstream.ai/mcp" and
  .mcpServers.meetstream.headers.Authorization == "Bearer ${MEETSTREAM_API_KEY}"
' "$PLUGIN_DIR/.mcp.json" >/dev/null || fail ".mcp.json compatibility adapter does not mirror the hosted MCP configuration"

[[ -d "$PLUGIN_DIR/skills" ]] || fail "skills/ is missing"
skill_count=0
while IFS= read -r -d '' skill_dir; do
  [[ -f "$skill_dir/SKILL.md" ]] || fail "immediate skill directory lacks SKILL.md: $skill_dir"
  grep -q '^name:' "$skill_dir/SKILL.md" || fail "skill metadata lacks name: $skill_dir/SKILL.md"
  grep -q '^description:' "$skill_dir/SKILL.md" || fail "skill metadata lacks description: $skill_dir/SKILL.md"
  skill_count=$((skill_count + 1))
done < <(find "$PLUGIN_DIR/skills" -mindepth 1 -maxdepth 1 -type d -print0)
[[ "$skill_count" -ge 5 ]] || fail "expected at least five packaged skills, found $skill_count"

core_skill="$PLUGIN_DIR/skills/meetstream/SKILL.md"
grep -q 'list-agents.sh' "$core_skill" || fail "MIA listing flow is not documented in the core skill"
grep -q 'send-bot.sh' "$core_skill" || fail "send-agent flow is not documented in the core skill"
grep -q 'remove-bot.sh --current' "$core_skill" || fail "current-call removal flow is not documented in the core skill"

for script in list-agents.sh send-bot.sh remove-bot.sh api-request.sh; do
  [[ -x "$PLUGIN_DIR/scripts/$script" ]] || fail "required tested script is missing or not executable: scripts/$script"
done

for reference in PRODUCT-AND-SETUP.md OPERATIONS.md MIA.md CALENDARS.md WEBHOOKS.md STREAMING.md API-REFERENCE.md DOCS-INDEX.md openapi.json; do
  [[ -s "$PLUGIN_DIR/references/$reference" ]] || fail "focused reference is missing or empty: references/$reference"
done

grep -q 'universal-2' "$PLUGIN_DIR/scripts/send-bot.sh" || fail "AssemblyAI model is outdated"
grep -q 'saaras:v3' "$PLUGIN_DIR/scripts/send-bot.sh" || fail "Sarvam model is outdated"
grep -q 'deepgram_streaming:{model:"nova-2"' "$PLUGIN_DIR/scripts/send-bot.sh" || fail "Deepgram Streaming model is outdated"
grep -q 'references/OPERATIONS.md' "$core_skill" || fail "core skill does not route bot operations to the focused guide"
grep -q 'scripts/api-request.sh' "$core_skill" || fail "core skill does not document the advanced API wrapper"

if grep -RIE --exclude='.env.example' --exclude-dir='.git' \
  '(MEETSTREAM_API_KEY|Authorization)[[:space:]]*[:=][[:space:]]*(ms_[A-Za-z0-9_-]{8,}|Bearer[[:space:]]+[A-Za-z0-9_-]{16,})' \
  "$PLUGIN_DIR" >/dev/null; then
  fail "possible literal credential found in package"
fi

grep -q 'Native OpenClaw' "$PLUGIN_DIR/README.md" || fail "README does not describe native OpenClaw packaging"
grep -q 'chatCompletions: { enabled: false }' "$PLUGIN_DIR/README.md" || fail "safe Gateway endpoint guidance is missing"
grep -q 'responses: { enabled: false }' "$PLUGIN_DIR/README.md" || fail "Responses endpoint safety guidance is missing"
grep -q 'They are disabled by default' "$PLUGIN_DIR/README.md" || fail "Gateway default-disabled warning is missing"
grep -q 'bind: "loopback"' "$PLUGIN_DIR/README.md" || fail "loopback Gateway binding is missing"
grep -q 'auth: { mode: "token" }' "$PLUGIN_DIR/README.md" || fail "Gateway authentication guidance is missing"
grep -q 'MIA x OpenClaw' "$PLUGIN_DIR/README.md" || fail "reference integration is not linked"
grep -q 'openclaw-x-meetstream-skill-1.1.0.tgz' "$PLUGIN_DIR/README.md" || fail "README does not point to the current native release archive"
echo "PASS: native OpenClaw manifest/runtime layout, auth, required flows, and security guidance"
