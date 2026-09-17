# Changelog

## 1.1.0 - 2026-09-16

- Convert the package to a native OpenClaw plugin with
  `openclaw.plugin.json`, a strict empty configuration schema, native skill and
  hosted-MCP declarations, an in-process runtime entry, and OpenClaw 2026.9.1
  compatibility metadata.

- Update supported transcription payloads to AssemblyAI `universal-2`, Sarvam
  `saaras:v3` with `transcribe`, and Deepgram Streaming `nova-2`.
- Add focused setup, operations, MIA, calendar, webhook, and streaming guides,
  with task-based routing from the core skill.
- Add a pinned-origin advanced API wrapper and reviewed OpenAPI snapshot for
  documented operations not covered by a dedicated script or MCP tool.
- Enforce current recording-duration and native-caption platform constraints,
  handle empty `204` responses, and clarify transcript readiness behavior.
- Keep request bodies out of process arguments when scripts call the API.
- Improve archive-install, first-bot, macOS, Windows/WSL2, and VS Code guidance.

## 1.0.2 - 2026-09-04

- Replace the unsupported `git:` install example with a tested one-action
  download plus archive install. OpenClaw `2026.9.1` routes Git sources through
  the native JavaScript-plugin contract, while Agent Plugin bundles install
  through local/archive or ClawHub sources.
- Clarify that `package.json` is dependency-free release metadata, not a native
  OpenClaw runtime manifest.

## 1.0.1 - 2026-09-04

- Add the dependency-free `package.json` required by OpenClaw's Git install
  staging path. Local archive and linked installs already worked in `1.0.0`;
  Git-based one-step installation is fixed in this release.

## 1.0.0 - 2026-09-04

- Package the integration as an Agent Plugins 1.0 bundle.
- Add the hosted MeetStream Streamable HTTP MCP server with per-request Bearer
  authentication through `MEETSTREAM_API_KEY`.
- Move the core OpenClaw skill into the portable `skills/` layout.
- Preserve tested REST scripts for MIA discovery and ambiguity-safe bot
  operations not fully represented by hosted MCP tools.
- Add macOS, Windows/WSL2, Terminal, and VS Code setup documentation.
- Document the minimum safe OpenClaw Gateway boundary; no OpenAI-compatible
  inbound endpoint is required.
- Add package validation, 58 offline operation tests, a safe recorded demo,
  MIT licensing, security policy, and ClawHub publishing instructions.
