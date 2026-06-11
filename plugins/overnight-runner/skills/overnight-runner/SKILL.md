---
name: overnight-runner
description: Use when executing a long autonomous todo-file run (multi-hour, unattended, or "work through this list overnight") — wraps the run in the overnight-runner state guard so every checked item has recorded evidence and completion gates (tests, browser verification, rollback) pass or are explicitly waived.
---

# Overnight Runner

The `overnight-runner` CLI (installed at `~/.local/bin/overnight-runner` from
https://github.com/rizonetech/overnight-runner) keeps long autonomous runs honest. You
do the work; the guard records evidence and refuses a final answer until the record
supports it.

Always run it with the Claude state base:

```bash
export OVERNIGHT_RUNNER_BASE=.claude/overnight
```

If `overnight-runner` is not on PATH, do NOT improvise — tell the user and offer:
`curl -fsSL https://raw.githubusercontent.com/rizonetech/overnight-runner/main/scripts/install.sh | bash`

## Run protocol

1. **Start**: `overnight-runner start <todo.md>` — runs pre-flight (module detection,
   ChromeMCP health) and an adversarial todo review. Read the review output; add any
   guardrail items it proposes to the todo before working.
   **Re-entering a todo that already has state** (a relaunch, a new session on the
   same list): use `overnight-runner start --resume <todo.md>` instead — it preserves
   the accumulated notes, blockers, slices, and rollback manifest while refreshing
   pre-flight. `--resume` is always safe: with no matching prior state it falls back
   to a normal fresh start.
2. **Work slice by slice.** After each meaningful step record it:
   `overnight-runner update --note "<what was done>" --gate <gate>=<status> ...`
   Never check a todo item without evidence recorded in the same update.
3. **Browser gates**: `browser_verification` gates are satisfied through the
   chromemcp-browser skill (real MCP evidence). If the run genuinely has no UI work,
   the run may have been started with `--no-browser` — the waiver is recorded and must
   be echoed in the handoff, never hidden.
4. **Blockers**: when stuck, record it (`overnight-runner update --blocker "<why>"`)
   and move to independent items instead of retrying in a loop.
5. **Finish**: `overnight-runner finish-check` must pass before you claim completion.
   If it fails, fix what it names or report honestly what is blocked.
   Then `overnight-runner handoff` and include its output in your final report.

## Hard rules

- The guard's word beats your memory: if state says a gate is pending, it is pending.
- Never edit the state JSON by hand; only through the CLI.
- Never delete or reword existing todo items to make them pass; fix the work instead.
- `overnight-runner status` is cheap — run it whenever you resume or feel lost.
