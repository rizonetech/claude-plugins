#!/usr/bin/env bash
# Launched by a systemd user timer armed via /overnight-runner:schedule.
# Args: <project-dir> <todo-file> <permission-mode>
set -euo pipefail

PROJECT_DIR="${1:?project dir required}"
TODO_FILE="${2:?todo file required}"
PERMISSION_MODE="${3:-acceptEdits}"

cd "$PROJECT_DIR"
export OVERNIGHT_RUNNER_BASE=.claude/overnight
REPORT_DIR="$PROJECT_DIR/.claude/overnight/reports"
mkdir -p "$REPORT_DIR"
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
"$CLAUDE" -p "/overnight-runner:start $TODO_FILE" \
  --output-format text \
  --permission-mode "$PERMISSION_MODE" \
  >> "$REPORT" 2>&1 || echo "claude exited non-zero: $?" >> "$REPORT"
echo "overnight-runner unattended run finished $(date -Is)" >> "$REPORT"
