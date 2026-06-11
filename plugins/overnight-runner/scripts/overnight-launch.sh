#!/usr/bin/env bash
# Launched by a systemd user timer armed via /overnight-runner:schedule.
# Args: <project-dir> <todo-file> <permission-mode>
set -euo pipefail

PROJECT_DIR="${1:?project dir required}"
TODO_FILE="${2:?todo file required}"
PERMISSION_MODE="${3:-acceptEdits}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$PROJECT_DIR"
export OVERNIGHT_RUNNER_BASE=.claude/overnight
REPORT_DIR="$PROJECT_DIR/.claude/overnight/reports"
mkdir -p "$REPORT_DIR"

# Concurrency lock: only one launch per project at a time. Watchdog timers can
# call this script freely — it exits 0 immediately while a run is alive. The
# kernel releases the flock when the holding process dies (any exit, crash, or
# kill), so no stale-lock handling is needed.
LOCKFILE="$PROJECT_DIR/.claude/overnight/launch.lock"
exec 9>"$LOCKFILE"
flock -n 9 || { echo "run already active, launch skipped $(date -Is)"; exit 0; }

REPORT="$REPORT_DIR/run-$(date +%Y%m%d-%H%M%S).log"

# systemd user units don't inherit the login shell's PATH; resolve claude
# explicitly. CLAUDE_BIN overrides; then PATH, then common install homes.
resolve_claude() {
  if [ -n "${CLAUDE_BIN:-}" ] && [ -x "$CLAUDE_BIN" ]; then echo "$CLAUDE_BIN"; return; fi
  if command -v claude >/dev/null 2>&1; then command -v claude; return; fi
  for c in "$HOME/.local/bin/claude" "$HOME/.claude/local/claude" \
           "$HOME"/.nvm/versions/node/*/bin/claude; do
    [ -x "$c" ] && { echo "$c"; return; }
  done
  return 1
}

echo "overnight-runner unattended run starting $(date -Is)" | tee "$REPORT"
CLAUDE="$(resolve_claude)" || { echo "FATAL: claude CLI not found (set CLAUDE_BIN)" >> "$REPORT"; exit 127; }
# stream-json through the formatter so the report streams progress live
# (plain `--output-format text` stays silent until the run ends). --resume is
# safe on a fresh todo: the guard falls back to a normal start when no prior
# state exists, and preserves notes/blockers/slices when one does.
set +o pipefail  # the pipeline must complete so PIPESTATUS captures claude's exit code
"$CLAUDE" -p "/overnight-runner:start --resume $TODO_FILE" \
  --output-format stream-json --verbose \
  --permission-mode "$PERMISSION_MODE" 2>&1 \
  | python3 "$SCRIPT_DIR/stream-report.py" \
  | tee -a "$REPORT"
CLAUDE_EXIT="${PIPESTATUS[0]}"
set -o pipefail
if [ "$CLAUDE_EXIT" -ne 0 ]; then
  echo "claude exited non-zero: $CLAUDE_EXIT" >> "$REPORT"
fi
echo "overnight-runner unattended run finished $(date -Is)" >> "$REPORT"
