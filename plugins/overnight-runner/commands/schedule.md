---
description: Arm an unattended overnight run (systemd user timer launching headless Claude on a todo file)
---

Schedule an unattended guarded run. Arguments: a todo file and a start time (e.g.
"02:00", "tomorrow 03:30"). Confirm both with the user if missing or ambiguous.

This arms real machine state — show the user the exact command before running it.

1. Pre-flight is built into the arm script (step 3): it verifies user systemd,
   the overnight-runner CLI, and linger. On a clean system, ask the user once
   whether to pass `--bootstrap` -- it auto-installs the CLI and enables
   linger; without it the script prints the exact fix commands and exits.
2. Ask the user which permission mode the unattended run gets. Recommend
   `bypassPermissions` for genuinely unattended runs and say why: with
   `acceptEdits` the headless session stalls at its FIRST Bash permission
   prompt (build, test, git) with nobody there to approve, and every watchdog
   relaunch stalls the same way -- the timer chain silently does nothing.
   Spell out the trade: `bypassPermissions` means unattended Claude runs shell
   commands without prompts. Whatever mode is chosen, the watchdog MUST be
   armed with the SAME mode as the main timer.
3. Arm main timer + watchdog in one portable step (works from any project
   root; installs a version-independent `~/.local/bin/overnight-launch` shim
   so the units survive plugin updates):
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/overnight-arm.sh "<todo.md>" --mode <permission-mode> --at "<resolved time>"`
   Defaults when flags are omitted: start 2 minutes out, watchdog every 30
   minutes, mode bypassPermissions. `--watchdog "<cadence>"` adjusts the
   relaunch cadence; `--no-watchdog` skips it (not recommended for unattended
   runs); re-running re-arms idempotently.
4. The watchdog relaunches a dead run within its cadence; the launch script's
   flock makes ticks no-ops while a run is alive. Usage limits are handled:
   the launch script parses the "resets <time>" hint from a limit-killed run
   and snoozes all launches (including watchdog ticks) until the reset --
   session limits resume the same day, weekly limits when the week rolls; no
   manual re-arming needed.
5. Confirm: `systemctl --user list-timers | grep overnight` and tell the user where
   the morning report will be: `.claude/overnight/reports/run-<timestamp>.log` (it
   streams live, so `tail -f` shows progress), and how to disarm both units:
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/overnight-arm.sh "<todo.md>" --disarm`.
   Remind the user to disarm the watchdog once the run is truly done, or it will
   keep relaunching on the same todo (harmless but noisy — the guard's finish
   gates keep it honest).
