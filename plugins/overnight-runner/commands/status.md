---
description: Report the current overnight-runner state — gates, blockers, progress, evidence
---

Read the guarded-run state for this project and summarize it for the user.

1. `export OVERNIGHT_RUNNER_BASE=.claude/overnight` then `overnight-runner status`.
   If that errors with no state found, also try without the env var (a codex-started
   run keeps state under `.codex/`) and say which base you found.
2. Present: run target (todo file), gates table (gate → status), open blockers with
   recovery hints, last update note + timestamp.
3. If a run looks finished, offer `overnight-runner finish-check`; if abandoned
   (stale timestamps), offer `overnight-runner clear`.
