---
description: Arm an unattended overnight run (systemd user timer launching headless Claude on a todo file)
---

Schedule an unattended guarded run. Arguments: a todo file and a start time (e.g.
"02:00", "tomorrow 03:30"). Confirm both with the user if missing or ambiguous.

This arms real machine state — show the user the exact command before running it.

1. Pre-flight: `command -v overnight-runner` (offer installer if missing);
   `systemctl --user is-system-running` must not error; warn if `loginctl show-user
   $USER --property=Linger` is not `Linger=yes` (timer dies on logout without it —
   fix: `loginctl enable-linger $USER`).
2. Ask the user which permission mode the unattended run gets:
   default `acceptEdits`; `bypassPermissions` only if they explicitly choose it —
   spell out that it means unattended Claude runs shell commands without prompts.
3. Arm the timer (PLUGIN_ROOT is this plugin's directory, available as
   ${CLAUDE_PLUGIN_ROOT}):
   `systemd-run --user --on-calendar="<resolved time>" --unit="overnight-$(basename $PWD)-$(date +%H%M)" bash ${CLAUDE_PLUGIN_ROOT}/scripts/overnight-launch.sh "$PWD" "<todo.md>" "<permission-mode>"`
4. Confirm: `systemctl --user list-timers | grep overnight` and tell the user where
   the morning report will be: `.claude/overnight/reports/run-<timestamp>.log`, and
   how to disarm: `systemctl --user stop <unit>.timer 2>/dev/null; systemctl --user stop <unit>.service 2>/dev/null`.
