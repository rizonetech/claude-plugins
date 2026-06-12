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
| `/overnight-runner:start` | Begin a guarded session on a todo file — pre-flight, adversarial todo review, gated execution, and a handoff at the end. |
| `/overnight-runner:status` | Read the current run state: gates table, open blockers, last update note, and next-step suggestions. |
| `/overnight-runner:schedule` | Arm a systemd user timer that launches headless Claude on a todo file unattended — confirms linger, permission mode, and disarm command before firing. |

## Platform requirement

**Linux or WSL2 with a user systemd instance. macOS and plain Windows are not
supported.** Unattended scheduling is built on `systemd-run --user` timers,
`loginctl` linger, and GNU coreutils (`date -d`); none of these exist on
macOS (launchd would need a separate port) or outside WSL2 on Windows. The
in-session pieces (`/overnight-runner:start`, `:status`) also assume a Linux
shell. On WSL2, enable systemd in `/etc/wsl.conf` (`[boot] systemd=true`)
before using `:schedule`.

## Prerequisites

- Linux/WSL2 with user systemd (see Platform requirement above)
- `overnight-runner` CLI installed and on PATH:

  ```
  curl -fsSL https://raw.githubusercontent.com/rizonetech/overnight-runner/main/scripts/install.sh | bash
  ```

  Installs to `~/.overnight-runner`, symlinks `overnight-runner` into `~/.local/bin`.
  Source: [github.com/rizonetech/overnight-runner](https://github.com/rizonetech/overnight-runner)

  On a clean system you can skip this: `scripts/overnight-arm.sh <todo.md> --bootstrap`
  installs the CLI and enables linger as part of its pre-flight.

- Python ≥ 3.10 (the CLI's only dependency; also used by the limit-snooze parser)

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
   `/overnight-runner:start todo/my-plan.md`
4. Claude runs pre-flight and an adversarial todo review — read the review output.
   If it proposes guardrail items, they are added to the todo before work begins.
5. Work proceeds slice by slice: after each step Claude records evidence and gate
   status. Browser tasks are verified through the `chromemcp-browser` skill.
6. At the end Claude runs `overnight-runner finish-check`. If it passes,
   `overnight-runner handoff` produces the structured morning summary.

## Schedule an unattended run

```
/overnight-runner:schedule todo/my-plan.md 02:00
```

Claude arms the main timer plus a watchdog through `scripts/overnight-arm.sh`
(portable: unit names derive from the project directory, and a version-independent
`~/.local/bin/overnight-launch` shim keeps timers working across plugin updates).
The watchdog relaunches a dead run on its cadence (default every 30 minutes); a
usage-limit death writes a snooze parsed from the "resets ..." hint, so session and
weekly limits are waited out and resumed automatically. To disarm both units:

```
bash <plugin>/scripts/overnight-arm.sh todo/my-plan.md --disarm
```

The morning report lands at `.claude/overnight/reports/run-<timestamp>.log`.

## License

MIT — see [LICENSE](../../LICENSE).
