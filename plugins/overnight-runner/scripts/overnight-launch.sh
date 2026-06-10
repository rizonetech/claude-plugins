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

echo "overnight-runner unattended run starting $(date -Is)" | tee "$REPORT"
claude -p "/overnight-runner:start $TODO_FILE" \
  --output-format text \
  --permission-mode "$PERMISSION_MODE" \
  >> "$REPORT" 2>&1 || echo "claude exited non-zero: $?" >> "$REPORT"
echo "overnight-runner unattended run finished $(date -Is)" >> "$REPORT"
