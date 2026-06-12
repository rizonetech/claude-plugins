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
2. Ask the user which permission mode the unattended run gets. Recommend
   `bypassPermissions` for genuinely unattended runs and say why: with
   `acceptEdits` the headless session stalls at its FIRST Bash permission
   prompt (build, test, git) with nobody there to approve, and every watchdog
   relaunch stalls the same way -- the timer chain silently does nothing.
   Spell out the trade: `bypassPermissions` means unattended Claude runs shell
   commands without prompts. Whatever mode is chosen, the watchdog MUST be
   armed with the SAME mode as the main timer.
3. Arm the timer (PLUGIN_ROOT is this plugin's directory, available as
   ${CLAUDE_PLUGIN_ROOT}):
   `systemd-run --user --on-calendar="<resolved time>" --unit="overnight-$(basename $PWD)-$(date +%H%M)" bash ${CLAUDE_PLUGIN_ROOT}/scripts/overnight-launch.sh "$PWD" "<todo.md>" "<permission-mode>"`
4. Arm the watchdog: a recurring timer (default hourly, same unit name with a
   `-watchdog` suffix) that runs the exact same launch invocation. The launch
   script's flock makes it a no-op while a run is alive and a relauncher when
   one died, so it is always safe to fire:
   `systemd-run --user --on-calendar="hourly" --unit="overnight-$(basename $PWD)-$(date +%H%M)-watchdog" bash ${CLAUDE_PLUGIN_ROOT}/scripts/overnight-launch.sh "$PWD" "<todo.md>" "<permission-mode>"`
   If the user wants a different cadence, adjust `--on-calendar` (e.g.
   `*:0/30` for every 30 minutes). Tell the user the watchdog is armed and that
   it relaunches a dead run within the hour. Usage limits are handled: the
   launch script parses the "resets <time>" hint from a limit-killed run and
   snoozes all launches (including watchdog ticks) until the reset -- session
   limits resume the same day, weekly limits when the week rolls; no manual
   re-arming needed.
5. Confirm: `systemctl --user list-timers | grep overnight` and tell the user where
   the morning report will be: `.claude/overnight/reports/run-<timestamp>.log` (it
   streams live, so `tail -f` shows progress), and how to disarm both units:
   `systemctl --user stop <unit>.timer <unit>-watchdog.timer 2>/dev/null; systemctl --user stop <unit>.service <unit>-watchdog.service 2>/dev/null`.
   Remind the user to disarm the watchdog once the run is truly done, or it will
   keep relaunching on the same todo (harmless but noisy — the guard's finish
   gates keep it honest).
