---
description: Diagnose and repair the ChromeMCP browser automation stack
---

Diagnose the ChromeMCP stack and repair what you find, step by step. Show the user
each check's result as you go.

1. **Install present?** `ls ~/ChromeMCP/chromemcp` and `command -v chromemcp`. If
   missing → stop and offer `/chromemcp:install`.
2. **Service**: `systemctl --user status chromemcp.service --no-pager | head -8`.
   If inactive: `chromemcp up`.
3. **Health**: `curl -fsS --max-time 5 http://127.0.0.1:8931/healthz`. Interpret:
   `"cdp":{"healthy":false}` → `chromemcp chrome`, wait 5s, re-check; still failing
   → `chromemcp bridge-check --fix` (warn: may show a Windows UAC prompt).
4. **Auth + MCP registration**: confirm `~/.config/chromemcp/token` exists and
   `claude mcp list 2>/dev/null | grep chromemcp` (or check `~/.claude.json`
   mcpServers) shows the `chromemcp` http server on port 8931. If missing, re-add:
   `claude mcp add --scope user --transport http chromemcp http://127.0.0.1:8931/mcp --header "Authorization: Bearer $(cat ~/.config/chromemcp/token)"`
5. **Smoke test**: `chromemcp test` — must end with "All checks passed".
6. **Version sync**: compare `cat ~/ChromeMCP/VERSION` with
   `cat ~/github/ChromeMCP/VERSION 2>/dev/null` — if the repo is newer, mention
   `chromemcp upgrade` (or `bash ~/github/ChromeMCP/scripts/install.sh --from-source`).

Finish with a one-table summary: check | status | action taken.
