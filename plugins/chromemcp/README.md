# chromemcp — Claude Code plugin

Drive a real, signed-in Windows Chrome from WSL2 inside Claude Code sessions.

The plugin wraps the [ChromeMCP](https://github.com/rizonetech/ChromeMCP) Playwright MCP
stack — a persistent, shared Chrome instance with a WSL2 bridge and auth proxy — and
gives Claude the discipline to use it reliably.

## What you get

| Item | What it does |
|---|---|
| `chromemcp-browser` skill | Health-check-first browser automation with tiered recovery and hard tab-discipline rules. Claude invokes this automatically for any task that needs real Chrome. |
| `/chromemcp:install` | Guided end-to-end bootstrap: installs the latest ChromeMCP release (via `npx @rizonetech/chromemcp install`) to `~/ChromeMCP`, configures the systemd user unit, launches Chrome with CDP, and registers the MCP server at user scope. |
| `/chromemcp:doctor` | Diagnoses and repairs a broken stack — checks install, service, health endpoint, auth token, and MCP registration, then summarises findings in a table. |

## Prerequisites

- Windows 11 + WSL2 (Ubuntu recommended)
- Node.js ≥ 18 in WSL2
- systemd user instance enabled (`[boot] systemd=true` in `/etc/wsl.conf`)
- The [ChromeMCP](https://github.com/rizonetech/ChromeMCP) stack (installed by `/chromemcp:install`)

## Install

Add the marketplace, then install the plugin:

```
/plugin marketplace add rizonetech/claude-plugins
/plugin install chromemcp@rizonetech
```

The plugin installs at user scope — it is available in every project immediately.

## First run

1. Install the plugin (above).
2. Run `/chromemcp:install` — Claude will walk through the full setup, tell you what
   each step does before running it, and pause on any failure.
3. Approve the Windows UAC prompt that appears on your Windows desktop when the
   WSL2 bridge is first configured.
4. When the install finishes, restart Claude Code (or run `/mcp`) so the new
   `chromemcp` MCP server connects.
5. Ask Claude to verify a page — e.g. *"Open my local dev server at localhost:3000
   and confirm the login page loads."* The `chromemcp-browser` skill takes over from
   there, running a health check before touching the browser.

## How the skill works

Before any browser action the skill curls `http://127.0.0.1:8931/healthz` and
checks that both `"status":"ok"` and `"cdp":{"healthy":true}` are present. If not,
it walks a recovery ladder — restarting the service, relaunching Chrome, or repairing
the bridge — before proceeding. It never claims browser verification passed when the
stack is unhealthy.

Tab discipline is enforced by rule: list tabs first, reuse the active tab, never open
a new tab to retry a failure, hard cap of 3 tabs, close what you open.

## Troubleshooting

Run `/chromemcp:doctor` — it checks every layer of the stack and prints a status
table with the action taken at each step.

For issues with the ChromeMCP infrastructure itself (service, bridge, Chrome),
see [github.com/rizonetech/ChromeMCP](https://github.com/rizonetech/ChromeMCP).

## License

MIT — see [LICENSE](../../LICENSE).
