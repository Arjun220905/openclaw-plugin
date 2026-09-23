# Demo recording

The repository includes a deterministic demo that exercises the three required
natural-language flows without touching a real meeting or using a real API
key. Bot creation and removal are directed to the loopback-only test server.

## Run it

```bash
bash demo/run-demo.sh
```

## Record it

### macOS Terminal

```bash
script -q demo/meetstream-openclaw-demo.log bash demo/run-demo.sh
```

Press Ctrl+D after the demo exits. The committed
`demo/meetstream-openclaw-demo.log` is the captured reference run.

### Windows / WSL2 / VS Code terminal

```bash
script -q -c "bash demo/run-demo.sh" demo/meetstream-openclaw-demo.log
```

For a screen video, record the same command with macOS Screenshot
(Shift+Command+5), Windows Snipping Tool, OBS, or your normal product-demo
recorder. Keep the terminal zoomed so the ambiguity refusal is readable.

## Live-demo extension

Only after the offline recording passes:

1. Install the plugin with the documented `openclaw plugins install` command.
2. Show `openclaw plugins inspect openclaw-x-meetstream-skill` and run
   `bash scripts/doctor.sh` for read-only REST and hosted-MCP probes.
3. In OpenClaw, ask “Show the MIA agents I can use.”
4. Use a dedicated meeting owned by the demo operator before showing the
   send/remove flows.
5. Never display `~/.openclaw/.env`, Gateway credentials, transcript content,
   private meeting URLs, or participant information in the recording.

## Acceptance checklist

- Manifest, version, MIT license, MCP URL, and unresolved auth variable appear.
- MIA agent listing is shown.
- Agent-name resolution dispatches a mock bot and returns a `bot_id`.
- “Current call” removal refuses multiple candidates rather than guessing.
- The final line confirms that no production credential or meeting was used.
