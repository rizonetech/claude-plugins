---
name: chromemcp-browser
description: Use when a task needs real Chrome browser automation — authenticated browser verification, CRUD testing, local web app testing, production smoke checks, screenshots, or visual QA evidence. Drives the shared ChromeMCP Playwright MCP server (Windows Chrome via WSL bridge) registered in Claude Code as the `chromemcp` MCP server.
---

# ChromeMCP Browser

ChromeMCP exposes a real, signed-in Windows Chrome to this session through the
`chromemcp` MCP server (`mcp__chromemcp__*` tools, load via ToolSearch). The browser is
shared and persistent: same tabs, cookies, and logins across all sessions and clients.

## Health check first — always

Before any browser work, verify the stack:

```bash
curl -fsS --max-time 5 http://127.0.0.1:8931/healthz
```

Healthy means `"status":"ok"` and `"cdp":{"healthy":true}`. If healthy, proceed
directly to browser tools. If not, walk the recovery ladder below — in order, one
rung at a time, re-checking `/healthz` after each rung.

## Recovery ladder

1. **CDP unhealthy** (`"healthy":false` or connection refused on the gateway IP —
   usually the debug-port Chrome exited):
   `chromemcp chrome` (relaunches Windows Chrome with CDP; idempotent), wait 5s, re-check.
2. **Still unhealthy** (bridge drift after a Windows reboot/IP change):
   `chromemcp bridge-check --fix` (may trigger a one-time Windows UAC prompt), re-check.
3. **healthz itself unreachable** (server down):
   `chromemcp up`, wait 5s, re-check.
4. **`chromemcp` command not found or ~/ChromeMCP missing** — ChromeMCP is not
   installed. Do NOT improvise an install; tell the user and offer to run
   `/chromemcp:install` (guided bootstrap).
5. **Ladder exhausted** — run `chromemcp status` and `chromemcp logs | tail -50`,
   report findings to the user. Never claim browser verification passed when the
   stack is unhealthy.

## Tab discipline — hard rules

The shared browser accumulates tabs across sessions; runaway tab creation has
historically opened hundreds of tabs. These rules are not optional:

1. **List before you act.** First browser action of a session: `browser_tabs`
   (action: list). Know what exists.
2. **Reuse the current tab.** `browser_navigate` navigates the active tab — that is
   the default way to change pages. Do not open a new tab to "start fresh".
3. **Never retry by opening a new tab.** If navigation fails or times out, that is a
   health problem — go to the recovery ladder. Opening another tab and retrying is
   how hundreds of tabs happen.
4. **Hard cap: 3 tabs.** Only open a new tab when the task genuinely requires two
   pages simultaneously (e.g. comparing). If `browser_tabs` lists more than 3, close
   the extras you created; leave tabs you did not create alone unless the user says
   otherwise.
5. **Close what you open.** Before finishing, close any tab you created.

## Working method

- After every navigate/click/type, use `browser_snapshot` (accessibility tree) to see
  the result — it is cheaper and more reliable than screenshots for driving actions.
- Use `browser_take_screenshot` only for visual evidence the user will look at.
- For dialogs (alert/confirm), handle with `browser_handle_dialog` — they block
  everything until handled.
- If the `chromemcp` MCP server is not connected in this session, health-check first,
  then suggest the user run `/mcp` to reconnect rather than falling back to curl.

## Evidence

Screenshots land in `~/ChromeMCP/mcp/.playwright-mcp/`. Read the PNG back to confirm
visual claims before reporting them. If `chromemcp test` fails, fix ChromeMCP before
claiming browser verification passed.
