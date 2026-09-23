# Security policy

## Supported versions

Security fixes are applied to the latest published release. Pin installations
to a reviewed release tag or commit and update deliberately.

## Reporting a vulnerability

Use GitHub's private vulnerability reporting for this repository, or email
`hello@meetstream.ai`. Do not open a public issue containing credentials,
meeting links, bot IDs, participant data, transcript content, or exploit
details.

Include the affected version, operating system, smallest safe reproduction,
security impact, and whether a MeetStream API key may have been exposed. Revoke
and replace any key that may have entered logs, shell history, screenshots, or
an untrusted file.

## Trust boundary

This repository is a native OpenClaw plugin. OpenClaw loads `index.js`
in-process, then reads the declared skills and connects to the declared remote
MCP server. The runtime entry is deliberately side-effect free; it does not
create network listeners, invoke APIs, or execute shell commands during
registration. Reviewed shell scripts still run only through the agent's normal
tool policy.

The native manifest declares exactly one remote MCP destination:
`https://mcp.meetstream.ai/mcp`. OpenClaw expands
`${MEETSTREAM_API_KEY}` at Gateway activation and sends it as a Bearer token on
each outbound MCP request. The deterministic REST scripts send the same account
credential only to `https://api.meetstream.ai/api/v1` using the REST API's
`Token` authentication scheme.

`workingDirectory: "."` in the native MCP declaration is compatibility
metadata for OpenClaw 2026.9.1. It prevents the bundle loader from adding an
unsupported `cwd` field to a remote Streamable-HTTP connection; it does not
start a local process or grant additional filesystem access.

Installing any native plugin executes its runtime and grants its instructions
and declared tools influence over agent behavior. Review
`openclaw.plugin.json`, `index.js`, `skills/`, and `scripts/` before
installation. Use OpenClaw tool allow/deny policy to restrict agents that do
not need meeting-changing actions.

## Gateway boundary

This plugin does not require an inbound OpenClaw HTTP endpoint. Keep the
OpenAI-compatible Chat Completions and Responses endpoints disabled. They are
disabled by default and, if enabled, a shared Gateway token/password represents
broad owner/operator authority rather than a narrow end-user permission.

Keep the Gateway bound to loopback or authenticated private ingress. Never
publish it directly to the internet. Use token or password authentication,
protect the shared credential, and keep OpenClaw updated.

## Security invariants

- No real credential is committed to the repository, manifest, MCP URL, or
  literal MCP header.
- Production MCP egress is HTTPS to `mcp.meetstream.ai` only.
- Production REST egress is HTTPS to `api.meetstream.ai/api/v1` only.
- The advanced wrapper accepts only API-relative paths, rejects traversal and
  fragments, never follows redirects, and cannot select another origin.
- JSON request bodies are passed to `curl` over stdin so provider secrets and
  storage credentials are not exposed in process arguments.
- `.env` is parsed as data and never executed by the scripts.
- Local credential files must be regular, non-symlink files with mode `0600`.
- Bot creation and removal require explicit, unambiguous user intent.
- “Current bot” resolution fails closed for zero, multiple, or paginated
  candidates.
- Meeting URLs are restricted to supported HTTPS providers.
- Callback, avatar, and live-transcript destinations must be public HTTPS URLs.
- Transcripts, chat, participant data, and presigned media URLs are treated as
  sensitive meeting data.
- Offline tests use a loopback-only mock and a dummy API key.
