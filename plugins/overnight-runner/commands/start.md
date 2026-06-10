---
description: Begin a guarded overnight-runner session on a todo file (pre-flight, adversarial review, gated execution)
---

Run a guarded todo execution in this session. The argument is the todo file path
(default: ask the user if not given).

1. Verify the CLI: `command -v overnight-runner` — if missing, offer the installer
   one-liner from the overnight-runner skill and stop.
2. `export OVERNIGHT_RUNNER_BASE=.claude/overnight`, then
   `overnight-runner start <todo.md>` and show the user the pre-flight + adversarial
   review results. If the review proposes guardrail items, add them to the todo file.
3. Work the todo per the overnight-runner skill's run protocol: evidence with every
   update, browser gates through the chromemcp-browser skill, blockers recorded —
   never silently skipped.
4. End with `overnight-runner finish-check` and `overnight-runner handoff`; include
   the handoff in your summary.
