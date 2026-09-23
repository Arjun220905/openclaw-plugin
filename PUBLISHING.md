# Publishing

The source is MIT licensed and ready to publish from the official
[MeetStream OpenClaw repository](https://github.com/meetstream-ai/openclaw-plugin).
Publish immutable releases from that repository's default branch after CI
passes.

## GitHub release

1. Confirm `openclaw.plugin.json`, `plugin.json`, `package.json`, and the
   release tag use the same SemVer.
2. Confirm the repository metadata points to
   `https://github.com/meetstream-ai/openclaw-plugin`.
3. Run `bash tests/validate_package.sh` and `bash tests/run_tests.sh`.
4. Run `./tests/verify_native_install.sh` to install a clean archive into an
   isolated state directory and verify native runtime registration.
5. Tag the reviewed commit, for example `v1.1.0`.
6. Attach the release archive, checksum, and demo recording to the GitHub
   release.

Users can then pin the archive install in one shell action:

```bash
release_tmp="$(mktemp -d)" && curl -fsSL "https://github.com/meetstream-ai/openclaw-plugin/releases/download/v1.1.0/openclaw-x-meetstream-skill-1.1.0.tgz" -o "$release_tmp/openclaw-x-meetstream-skill-1.1.0.tgz" && openclaw plugins install "$release_tmp/openclaw-x-meetstream-skill-1.1.0.tgz"
```

The archive is the release artifact users should pin. This project is a native
plugin, so verify `openclaw.plugin.json`, `index.js`, and runtime inspection
before publishing.

## Optional ClawHub publication

ClawHub supports native plugins and GitHub sources. The publisher must
choose an owner/namespace and authenticate; that ownership decision is not
stored in this repository.

```bash
npm install -g clawhub
clawhub login
clawhub package validate .
clawhub package publish . --dry-run
clawhub package publish . --wait
```

After publication, document the exact package name and use:

```bash
openclaw plugins install clawhub:<published-package-name>
```

Do not use `clawhub skill publish`; this repository is a native plugin with
multiple skills and an MCP server. A live ClawHub publish should occur only
after the publisher owner is confirmed and the dry-run output, native runtime
inspection, source commit, file list, and security scan are reviewed.
