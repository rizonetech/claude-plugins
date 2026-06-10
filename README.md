# claude-plugins

Rizonetech's Claude Code plugin marketplace — thin, composable plugins for Claude Code.

## Install

```
/plugin marketplace add rizonetech/claude-plugins
/plugin install chromemcp@rizonetech
```

## Plugins

| Plugin | Version | Description |
|---|---|---|
| [`chromemcp`](plugins/chromemcp/README.md) | 0.1.1 | Drive a real, signed-in Windows Chrome from WSL2 via the ChromeMCP Playwright MCP stack. |

## How this marketplace works

Plugins here are intentionally thin: they ship model-facing skills and slash commands,
while the actual infrastructure lives in its own repo and installs independently.
Installing a plugin has no side effects — it only adds knowledge to Claude.
Once installed at user scope (`--scope user` is the default), the plugin is available
in every project without any per-project setup.

## Requirements — chromemcp

- Windows 11 with WSL2 (Ubuntu recommended)
- The [ChromeMCP](https://github.com/rizonetech/ChromeMCP) stack installed at `~/ChromeMCP`
- Node ≥ 18, systemd user instance enabled in WSL2

The `/chromemcp:install` slash command guides the full setup end to end.

## License

MIT — see [LICENSE](LICENSE).
