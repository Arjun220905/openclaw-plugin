# MeetStream for OpenClaw

An installable, MIT-licensed Native OpenClaw plugin for managing
[MeetStream](https://meetstream.ai) meeting bots and MIA agents in natural
language. It uses an in-process OpenClaw runtime, native skill declarations,
and a native hosted-MCP declaration. `plugin.json` and `mcp.json` remain as
cross-client compatibility metadata.

Source repository: [meetstream-ai/openclaw-plugin](https://github.com/meetstream-ai/openclaw-plugin).

```bash
npm pack
openclaw plugins install ./openclaw-x-meetstream-skill-1.1.0.tgz
```

That command installs the native manifest, runtime, skills, and hosted MCP
connection as one reviewable plugin. There is no project-specific install
script.

> This repository is the packaged sibling of
> [MIA x OpenClaw: Bring an OpenClaw Agent into a Live Meeting](https://github.com/meetstream-ai/labs/tree/main/MIA-chat-agent).
> The reference integration proves the live bridge; this repository makes the
> management surface installable for third parties.

## What it enables

After setup, ask OpenClaw:

- “Show the MIA agents I can use.”
- “Send my standup agent to `https://meet.google.com/abc-defg-hij`.”
- “What bots are in a call right now?”
- “Remove the bot from the current call.”
- “Get the transcript and summary for bot `<id>`.”

The plugin combines two deliberately small surfaces:

1. `openclaw.plugin.json` connects OpenClaw to
   `https://mcp.meetstream.ai/mcp` using
   Streamable HTTP. OpenClaw expands `MEETSTREAM_API_KEY` into a Bearer header
   on each outbound MCP request.
2. The tested scripts in `scripts/` cover REST-only MIA discovery, guarded
   fallbacks, and a pinned-origin advanced wrapper for documented operations
   absent from the available MCP tool catalog. They refuse to guess when an
   agent name or “current bot” is ambiguous.

The manifest's `workingDirectory: "."` is intentional compatibility metadata
for OpenClaw 2026.9.1: it prevents the native bundle loader from injecting a
`cwd` field into a remote Streamable-HTTP connection. It does not execute a
local process or change the remote MCP request.

The hosted MCP server exposes the normal bot, transcript, media, participant,
chat, speaker, calendar, and webhook-guide tools. MIA configuration listing is
currently REST-only, which is why the small script layer remains part of the
package.

The core skill routes each request to a focused guide instead of loading the
entire API reference: product/setup, bot operations, MIA, calendars, webhooks,
streaming, or advanced API schemas. The current transcription defaults include
AssemblyAI `universal-2`, Sarvam `saaras:v3` in `transcribe` mode, and Deepgram
Streaming `nova-2`.

## Requirements

- OpenClaw `2026.9.1` or later, which loads the native runtime and manifest
- a [MeetStream API key](https://app.meetstream.ai/api-key)
- `curl` and `jq` for the REST-only MIA and guarded-current-bot flows
- macOS, Linux, or Windows with OpenClaw running in WSL2

See [QUICKSTART.md](./QUICKSTART.md) for macOS, Windows, Terminal, and VS Code
instructions.

## Install and configure

### 1. Install the native plugin

```bash
npm pack
openclaw plugins install ./openclaw-x-meetstream-skill-1.1.0.tgz
```

OpenClaw loads native runtime code in-process. Review `openclaw.plugin.json`,
`index.js`, skills, MCP destination, and scripts before accepting installation.
The runtime is deliberately side-effect free; bot operations remain explicit
MCP or script calls. Before the first official release exists, build and
install the local archive above. [PUBLISHING.md](./PUBLISHING.md) contains the
one-action immutable-release command maintainers publish afterward.

### 2. Store the API key on the Gateway host

OpenClaw services do not reliably inherit your interactive shell. Put the key
in OpenClaw's global runtime file, not in this repository:

```bash
mkdir -p ~/.openclaw
chmod 700 ~/.openclaw
${EDITOR:-nano} ~/.openclaw/.env
chmod 600 ~/.openclaw/.env
```

Add one line in the editor:

```dotenv
MEETSTREAM_API_KEY=your_key_here
```

Do not paste a real key into a command argument, chat, issue, screenshot, or
committed file.

### 3. Restart and verify

```bash
openclaw gateway restart
openclaw plugins inspect openclaw-x-meetstream-skill
openclaw plugins doctor
```

Then ask: “Show the MIA agents I can use.”

From a source checkout, `bash scripts/doctor.sh` additionally performs
read-only live REST and hosted-MCP authentication probes. An archive-only user
does not need to keep a checkout just to complete installation.

## How OpenClaw fits

OpenClaw is the agent runtime. Its Gateway hosts your agent sessions, applies
tool policy, loads this plugin's skills, and connects outbound to MeetStream's
MCP server. The plugin does not provide a model, a chat UI, or a public inbound
endpoint.

```text
You -> OpenClaw agent -> MeetStream skill
                         |-> hosted MCP (Bearer key per request)
                         `-> tested REST scripts (Token key per request)
                                   -> MeetStream API
```

The authentication schemes are intentionally different: the MeetStream REST
API uses `Authorization: Token ...`; the hosted MCP server uses
`Authorization: Bearer ...`.

## Minimum safe Gateway configuration

This plugin makes an outbound HTTPS connection. It does **not** require either
OpenClaw's OpenAI-compatible Chat Completions endpoint or Responses endpoint.
Both should remain disabled unless a separate, reviewed integration needs one.

Minimum safe posture:

```json5
{
  gateway: {
    mode: "local",
    bind: "loopback",
    auth: { mode: "token" },
    http: {
      endpoints: {
        chatCompletions: { enabled: false },
        responses: { enabled: false }
      }
    }
  }
}
```

- Keep the Gateway on loopback, a private tailnet, or authenticated private
  ingress. Never expose it directly to the public internet.
- Keep token/password authentication enabled and protect that credential as an
  owner/operator secret.
- Limit this plugin with OpenClaw tool policy if an agent should not create,
  remove, message, or schedule bots. Deny the exposed MeetStream MCP tools for
  agents that do not need them.
- Do not enable the OpenAI-compatible endpoints merely to make this plugin
  work. They are disabled by default and a valid shared Gateway credential is
  equivalent to broad operator access.

See [SECURITY.md](./SECURITY.md) for the review boundary and reporting policy.

## Package layout

```text
openclaw.plugin.json                native OpenClaw manifest, skills, and MCP
index.js                            side-effect-free native runtime entry
package.json                        native runtime, host compatibility, metadata
plugin.json + mcp.json              Agent Plugin compatibility metadata
skills/meetstream/SKILL.md          required natural-language flows
skills/meetstream-*/SKILL.md        focused builder/calendar/debug skills
scripts/*.sh                        deterministic REST operations
scripts/api-request.sh              guarded advanced REST wrapper
references/*.md                     focused setup/operations/MIA guides
references/openapi.json             reviewed API schema snapshot
tests/mock_server.py                loopback-only API fixture
tests/run_tests.sh                  behavior and security regression tests
tests/validate_package.sh           manifest/layout/security validation
```

This is a native OpenClaw plugin. Confirm native registration with
`openclaw plugins inspect openclaw-x-meetstream-skill --runtime --json`; it
must report `format: "openclaw"`, the `meetstream` MCP server, and no
diagnostics. Use `bash scripts/doctor.sh` for a read-only live REST/MCP probe.

## Development and verification

No production API key is needed for the offline suite:

```bash
bash tests/validate_package.sh
bash tests/run_tests.sh
./tests/verify_native_install.sh
shellcheck -x tests/*.sh demo/*.sh
(cd scripts && shellcheck -x *.sh)
```

Test a local checkout through OpenClaw's managed plugin path:

```bash
openclaw plugins install --link .
openclaw plugins inspect openclaw-x-meetstream-skill --runtime --json
openclaw gateway restart
```

The mock server binds to an ephemeral `127.0.0.1` port, uses a dummy key, and
cannot redirect a production credential. The scripts pin production REST
egress to `https://api.meetstream.ai/api/v1`.

## Focused operation guides

- [Product and OpenClaw setup](./references/PRODUCT-AND-SETUP.md)
- [Bot operations and transcription providers](./references/OPERATIONS.md)
- [MIA configuration](./references/MIA.md)
- [Calendar connections and scheduling](./references/CALENDARS.md)
- [Webhook lifecycle and verification](./references/WEBHOOKS.md)
- [Custom streaming bridges](./references/STREAMING.md)
- [Advanced API wrapper and schema](./references/API-REFERENCE.md)

## Demo and release

- [DEMO.md](./DEMO.md) contains the safe recording script and acceptance
  checklist.
- Release archives can be installed directly:
  `openclaw plugins install ./openclaw-x-meetstream-skill-1.1.0.tgz`.
- Versioned archives and ClawHub are supported distribution paths for this
  native plugin. Prefer a tagged release and pin production installs to that
  version.

Recommended sequencing: land and link the reference integration first, then
release this plugin against the exact API behavior it proves. They can be
announced together, but should remain separate artifacts so the demonstration
app and installable control surface can version independently.

## Related projects

- [MIA x OpenClaw reference integration](https://github.com/meetstream-ai/labs/tree/main/MIA-chat-agent)
- [MeetStream Claude plugin](https://github.com/meetstream-ai/claude-plugin)
- [MeetStream Cursor plugin](https://github.com/meetstream-ai/meetstream-cursor-plugin)
- [OpenClaw native plugins](https://docs.openclaw.ai/plugins)
- [MeetStream API documentation](https://docs.meetstream.ai)

## License

[MIT](./LICENSE)
