# MeetStream for OpenClaw: quick start

OpenClaw is the local agent runtime that receives your request, selects the
MeetStream skill, and calls either the hosted MeetStream MCP tools or the
package's tested scripts. Its Gateway must already be installed, onboarded
with a model provider, and running.

You also need a [MeetStream API key](https://app.meetstream.ai/api-key), plus
`curl` and `jq` for MIA listing and guarded script fallbacks.

## macOS — Terminal

```bash
# Install and onboard OpenClaw if needed
curl -fsSL https://openclaw.ai/install.sh | bash
openclaw onboard --install-daemon

# Install the MeetStream plugin in one step
npm pack
openclaw plugins install ./openclaw-x-meetstream-skill-1.1.0.tgz
```

Review the source warning and displayed skills capability, then accept the
installation. Review the native runtime, manifest, skills, and MCP destination
before accepting it.

If `jq` is missing, install it with `brew install jq`.

Store the API key without putting it in shell history:

```bash
mkdir -p ~/.openclaw
chmod 700 ~/.openclaw
${EDITOR:-nano} ~/.openclaw/.env
chmod 600 ~/.openclaw/.env
openclaw gateway restart
```

In the editor, add `MEETSTREAM_API_KEY=your_key_here`, save, and close.

## macOS — VS Code

1. Open VS Code.
2. Choose **Terminal → New Terminal**.
3. Run the same install command:

   ```bash
   npm pack
   openclaw plugins install ./openclaw-x-meetstream-skill-1.1.0.tgz
   ```

4. Choose **File → Open File**, enter `~/.openclaw/.env`, and add the key line.
   Do not open or save the key inside the cloned repository.
5. In the integrated terminal, run:

   ```bash
   chmod 600 ~/.openclaw/.env
   openclaw gateway restart
   ```

## Windows — OpenClaw in WSL2

Open PowerShell as Administrator once:

```powershell
wsl --install -d Ubuntu-24.04
```

Restart if prompted, open Ubuntu, and install/onboard OpenClaw there:

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
openclaw onboard --install-daemon
sudo apt-get update && sudo apt-get install -y curl jq
npm pack
openclaw plugins install ./openclaw-x-meetstream-skill-1.1.0.tgz
```

Then edit the Gateway's global environment file inside Ubuntu:

```bash
mkdir -p ~/.openclaw
chmod 700 ~/.openclaw
nano ~/.openclaw/.env
chmod 600 ~/.openclaw/.env
openclaw gateway restart
```

Add `MEETSTREAM_API_KEY=your_key_here` in `nano`, press Ctrl+O, Enter, then
Ctrl+X. Do not run the Bash scripts directly in PowerShell or Command Prompt.

## Windows — VS Code with WSL

1. Install VS Code and the **WSL** extension.
2. Press Ctrl+Shift+P and choose **WSL: Connect to WSL**.
3. Choose **Terminal → New Terminal**. Confirm the prompt is Ubuntu/WSL.
4. Run the same Ubuntu commands above.
5. Open `~/.openclaw/.env` from that WSL window, add the key, save it, then run
   `chmod 600 ~/.openclaw/.env` and `openclaw gateway restart`.

The native Windows Hub can manage OpenClaw, but this repository's tested shell
fallbacks run in WSL2. Keep the plugin, its dependencies, and the Gateway in
the same WSL environment.

## Verify

```bash
openclaw plugins inspect openclaw-x-meetstream-skill
openclaw plugins inspect openclaw-x-meetstream-skill --runtime --json
openclaw plugins doctor
```

If you also have a source checkout, run `bash scripts/doctor.sh` from its root
for read-only live REST and hosted-MCP probes. Archive-only installation does
not require a checkout.

Open OpenClaw and try:

- “Show the MIA agents I can use.”
- “Send my agent to this meeting: `<meeting URL>`.”
- “Remove the bot from the current call.”

Sending or removing a bot changes a real meeting. Use a meeting you are
authorized to affect. If more than one agent or active bot matches, the plugin
must ask you to choose rather than guessing.

For a first recording bot, give OpenClaw a real authorized meeting URL and say:

> Use MeetStream to join this meeting as Meeting Notetaker, record audio,
> transcribe with Deepgram, and retain it for 24 hours: `<meeting URL>`

Keep the returned bot ID. Admit the bot, confirm it is recording, remove it
when finished, and request the transcript after processing completes. An empty
MIA list is normal for recording-only bots; a speaking agent first needs a MIA
configuration in the MeetStream dashboard.

For more detail, see [product/setup](./references/PRODUCT-AND-SETUP.md),
[bot operations](./references/OPERATIONS.md), [MIA](./references/MIA.md),
[calendars](./references/CALENDARS.md), [webhooks](./references/WEBHOOKS.md),
and [streaming](./references/STREAMING.md).

## Important Gateway safety

This plugin only needs outbound HTTPS access to MeetStream. Leave OpenClaw's
OpenAI-compatible Chat Completions and Responses endpoints disabled. Keep the
Gateway on loopback/private ingress with token or password authentication; do
not expose it publicly. See [README.md](./README.md#minimum-safe-gateway-configuration).
