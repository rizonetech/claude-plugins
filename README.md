# claude-plugins

Rizonetech's Claude Code plugin marketplace.

## Install

    /plugin marketplace add rizonetech/claude-plugins
    /plugin install chromemcp@rizonetech

## Plugins

| Plugin | Description |
|---|---|
| `chromemcp` | Drive a real, signed-in Windows Chrome from WSL2 via [ChromeMCP](https://github.com/rizonetech/ChromeMCP). Health-check-first skill, tiered recovery, tab discipline, `/chromemcp:doctor` and `/chromemcp:install` commands. |

The `chromemcp` plugin is thin by design: the infrastructure (Playwright MCP server,
auth proxy, Windows bridge) lives in the [ChromeMCP](https://github.com/rizonetech/ChromeMCP)
repo and installs to `~/ChromeMCP`. The plugin ships the model-facing knowledge and
detects/offers installation on first use — installing the plugin itself has no side effects.
