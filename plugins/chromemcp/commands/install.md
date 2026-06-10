---
description: Guided install of the ChromeMCP stack (npm release install to ~/ChromeMCP, service, MCP registration)
---

Install the ChromeMCP stack end to end. This makes machine-level changes (systemd
user unit, Windows-side bridge with a UAC prompt, Chrome launch) — tell the user
what each step does before running it, and stop on any failure rather than
improvising.

1. **Pre-flight**: WSL2? (`grep -qi microsoft /proc/version`), Node ≥ 18
   (`node -v`), systemd user instance up (`systemctl --user is-system-running`).
   Report any missing prerequisite with its fix (e.g. `[boot] systemd=true` in
   `/etc/wsl.conf` + `wsl --shutdown`).
2. **Install**: `npx -y @rizonetech/chromemcp install` — downloads the latest
   GitHub release and installs to `~/ChromeMCP` (runs npm ci, symlinks
   `chromemcp` into `~/.local/bin`). Alternative for contributors or when a
   source checkout is preferred:
   `git clone https://github.com/rizonetech/ChromeMCP ~/github/ChromeMCP && bash ~/github/ChromeMCP/scripts/install.sh --from-source`
   (a source checkout also enables `chromemcp update`; release installs update
   via `chromemcp upgrade`).
3. **Bridge + Chrome** (Windows side): `chromemcp chrome` to launch Chrome with
   CDP. If CDP is not reachable from WSL afterwards, run `chromemcp setup-bridge`
   (first-time bridge install; later drift repairs use `chromemcp bridge-check
   --fix` instead) — warn the user a UAC prompt will appear on the Windows desktop
   and they must approve it.
4. **Service**: `chromemcp enable` (systemd user unit + linger).
5. **MCP registration** (user scope, applies to all projects):
   `claude mcp add --scope user --transport http chromemcp http://127.0.0.1:8931/mcp --header "Authorization: Bearer $(cat ~/.config/chromemcp/token)"`
6. **Verify**: `curl -fsS http://127.0.0.1:8931/healthz` shows `"status":"ok"` and
   `"cdp":{"healthy":true}`; `chromemcp test` ends with "All checks passed".
7. Tell the user to restart Claude Code (or run `/mcp`) so the new MCP server
   connects, then the `chromemcp-browser` skill takes over day-to-day use.
