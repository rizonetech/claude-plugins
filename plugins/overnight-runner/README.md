# overnight-runner — Claude Code plugin

Keep long autonomous Claude runs honest: every checked todo item needs recorded
evidence, completion gates must pass or be explicitly waived, and the run produces a
structured handoff you can trust in the morning.

The plugin wraps the [overnight-runner](https://github.com/rizonetech/overnight-runner)
state guard CLI and gives Claude the discipline to use it reliably.

## What you get

| Item | What it does |
|---|---|
| `overnight-runner` skill | Guards every long todo run: evidence-backed updates, browser verification through the chromemcp-browser skill, and a hard finish-check before any completion claim. |
| `/overnight:start` | Begin a guarded session on a todo file — pre-flight, adversarial todo review, gated execution, and a handoff at the end. |
| `/overnight:status` | Read the current run state: gates table, open blockers, last update note, and next-step suggestions. |
| `/overnight:schedule` | Arm a systemd user timer that launches headless Claude on a todo file unattended — confirms linger, permission mode, and disarm command before firing. |

## Prerequisites

- `overnight-runner` CLI installed and on PATH:

  ```
  curl -fsSL https://raw.githubusercontent.com/rizonetech/overnight-runner/main/scripts/install.sh | bash
  ```

  Installs to `~/.overnight-runner`, symlinks `overnight-runner` into `~/.local/bin`.
  Source: [github.com/rizonetech/overnight-runner](https://github.com/rizonetech/overnight-runner)

- Python ≥ 3.10 (the CLI's only dependency)
- For `/overnight:schedule`: systemd user instance enabled in WSL2

## Install

Add the marketplace, then install the plugin:

```
/plugin marketplace add rizonetech/claude-plugins
/plugin install overnight-runner@rizonetech
```

The plugin installs at user scope and is available in every project immediately.

## First run

1. Install the CLI (see Prerequisites above).
2. Install the plugin (above).
3. Open a project with a todo file (a Markdown checklist), then run:
   `/overnight:start todo/my-plan.md`
4. Claude runs pre-flight and an adversarial todo review — read the review output.
   If it proposes guardrail items, they are added to the todo before work begins.
5. Work proceeds slice by slice: after each step Claude records evidence and gate
   status. Browser tasks are verified through the `chromemcp-browser` skill.
6. At the end Claude runs `overnight-runner finish-check`. If it passes,
   `overnight-runner handoff` produces the structured morning summary.

## Schedule an unattended run

```
/overnight:schedule todo/my-plan.md 02:00
```

Claude confirms the linger setting, shows you the exact systemd-run command, then arms
the timer. To disarm before it fires:

```
systemctl --user stop overnight-<project>-<HHMM>.timer
systemctl --user stop overnight-<project>-<HHMM>.service
```

The morning report lands at `.claude/overnight/reports/run-<timestamp>.log`.

## License

MIT — see [LICENSE](../../LICENSE).
