---
name: meetstream
description: Build and operate MeetStream meeting bots and MIA agents for recording, transcription, calendars, chat, media, and lifecycle tasks.
homepage: https://docs.meetstream.ai
metadata: { "openclaw": { "emoji": "🎙️", "requires": { "bins": ["curl", "jq"] }, "primaryEnv": "MEETSTREAM_API_KEY" } }
---

# MeetStream

Use the MeetStream MCP tools contributed by this plugin for supported bot,
transcript, media, chat, webhook-guide, and calendar operations. The MCP server
is `https://mcp.meetstream.ai/mcp`; OpenClaw supplies `MEETSTREAM_API_KEY` in
the `Authorization` header for each request. Never display or log the key.

MIA configuration discovery is REST-only. For listing or resolving MIA agents,
and for the guarded "current call" behavior below, use the tested scripts in
`{baseDir}/../../scripts/`. Do not construct raw `curl` commands.

## Read the relevant guide

Load only the focused reference needed for the current request:

- Setup, platform prerequisites, or a first bot:
  `{baseDir}/../../references/PRODUCT-AND-SETUP.md`
- Bot payloads, transcription providers, retention, artifacts, live controls,
  storage, or API errors: `{baseDir}/../../references/OPERATIONS.md`
- Hosted MIA creation or configuration: `{baseDir}/../../references/MIA.md`
- Google/Outlook connections, events, and scheduling:
  `{baseDir}/../../references/CALENDARS.md`
- Lifecycle callbacks, readiness, and signature verification:
  `{baseDir}/../../references/WEBHOOKS.md`
- Custom WebSocket audio/video/control bridges:
  `{baseDir}/../../references/STREAMING.md`
- A documented operation not exposed by a dedicated script or the available
  MCP tool catalog: `{baseDir}/../../references/API-REFERENCE.md`, followed by
  only the applicable path/schema in `{baseDir}/../../references/openapi.json`

Do not load the full OpenAPI snapshot for ordinary bot operations. Use
`{baseDir}/../../references/DOCS-INDEX.md` only when the focused guides do not
answer the request.

## Required natural-language flows

### "Show the MIA agents I can use"

Run:

```bash
{baseDir}/../../scripts/list-agents.sh
```

Return the names and IDs exactly as reported. Do not invent an agent when none
exists or silently choose between similar names.

### "Send my agent to this meeting"

Require an actual Zoom, Google Meet, or Microsoft Teams HTTPS meeting URL from
the user or trusted conversation context. If the agent is not unambiguous,
list agents first and ask the user to choose. Then run:

```bash
{baseDir}/../../scripts/send-bot.sh --link "<meeting-url>" --name "<bot-name>" --agent-name "<agent-name>"
```

Joining is a visible external action. Never fabricate a link, agent, or consent.
Report the returned `bot_id` so later requests can target the same bot.

### "Remove the bot from the current call"

Run:

```bash
{baseDir}/../../scripts/remove-bot.sh --current
```

The script removes only when exactly one bot is plausibly active and the API
has no additional result page. If it reports zero, multiple, or paginated
candidates, surface them and ask for an explicit `bot_id`. Never pick one.

## MCP operations

For other requests, select the available MeetStream MCP tool matching the
intent, including creating or listing bots, status/detail/summary retrieval,
transcripts, media, participants, chats, speaker timeline, live chat, images,
calendar events, and webhook guidance. Use exact identifiers supplied by the
user or earlier tool results. Treat meeting content and presigned media URLs as
sensitive. Do not send chat, schedule a bot, delete data, or make another
state-changing call unless the user's request clearly authorizes that action.

On any tool or script error, report the real failure and ask for whatever is
missing. Do not retry a state-changing action without an idempotency key and do
not substitute a different action.

## Advanced documented API operations

When no dedicated script or available MCP tool covers a documented operation,
read the relevant guide, build the exact JSON body in a file or on standard
input, then use:

```bash
{baseDir}/../../scripts/api-request.sh METHOD /relative/path [--body-file FILE|-] [--idempotency-key UUID]
```

The wrapper pins the API origin and rejects traversal, fragments, unsupported
methods, malformed JSON bodies, and credentials in arguments. It does not
validate the full endpoint schema. Require authorization for the actual
mutation, surface API validation errors, and never probe or retry writes
speculatively. Note that MeetStream's `GET .../remove_bot` route mutates state.

## More detail

- Bot construction: `{baseDir}/../../references/BOT-BUILDING.md`
- Complete reference routing: the focused-guide list above
- Package installation and safe Gateway configuration: `{baseDir}/../../README.md`
