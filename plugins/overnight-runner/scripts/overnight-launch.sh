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

# Claim an isolated ChromeMCP lane (ChromeMCP >= 0.3.0) so this run cannot
# collide with concurrent overnight runs — codex lanes, other claude lanes,
# or an interactive session on the default stack. Best-effort: without
# chromemcp, a free lane, or a startable lane stack, the run proceeds on the
# default shared stack.
CHROMEMCP_BIN="$(command -v chromemcp || true)"
[ -z "$CHROMEMCP_BIN" ] && [ -x "$HOME/ChromeMCP/chromemcp" ] && CHROMEMCP_BIN="$HOME/ChromeMCP/chromemcp"
LANE=""
LANE_MCP_CONFIG=""
MCP_CONFIG_ARGS=()
cleanup_lane() {
  [ -n "$LANE_MCP_CONFIG" ] && rm -f "$LANE_MCP_CONFIG"
  if [ -n "$LANE" ]; then
    "$CHROMEMCP_BIN" lane down --client claude "$LANE" >> "$REPORT" 2>&1 || true
    "$CHROMEMCP_BIN" lane release --client claude "$LANE" >> "$REPORT" 2>&1 || true
  fi
}
trap cleanup_lane EXIT
if [ -n "$CHROMEMCP_BIN" ] && "$CHROMEMCP_BIN" lane help >/dev/null 2>&1; then
  if LANE_ENV="$("$CHROMEMCP_BIN" lane acquire --client claude \
        --owner "overnight-runner:$$" --format shell 2>> "$REPORT")"; then
    eval "$LANE_ENV"
    LANE="$CHROMEMCP_LANE"
    echo "claimed claude ChromeMCP lane $LANE ($MCP_URL)" >> "$REPORT"
    if "$CHROMEMCP_BIN" lane up --client claude "$LANE" >> "$REPORT" 2>&1; then
      TOKEN="$(MCP_TOKEN_PATH="$MCP_TOKEN_PATH" "$CHROMEMCP_BIN" token 2>/dev/null || true)"
      if [ -n "$TOKEN" ]; then
        # Same server name as the user-level registration so the lane URL
        # overrides it for this session only. mktemp is 0600; removed on exit.
        LANE_MCP_CONFIG="$(mktemp)"
        printf '{"mcpServers":{"chromemcp":{"type":"http","url":"%s","headers":{"Authorization":"Bearer %s"}}}}\n' \
          "$MCP_URL" "$TOKEN" > "$LANE_MCP_CONFIG"
        MCP_CONFIG_ARGS=(--mcp-config "$LANE_MCP_CONFIG")
      else
        echo "lane $LANE token unavailable; session keeps the default chromemcp registration" >> "$REPORT"
      fi
      export CHROMEMCP_MCP_URL="$MCP_URL"
    else
      echo "lane $LANE stack failed to start (bridge for CDP port $CDP_PORT not pre-installed?);" \
           "continuing on the default ChromeMCP stack" >> "$REPORT"
      unset CHROMEMCP_LANE CHROMEMCP_LANE_CLIENT CHROMEMCP_LANE_SUFFIX CHROMEMCP_CODEX_LANE_SUFFIX
    fi
    # Generic names leak into the session env and can confuse the project
    # under test (dev servers honor PORT); the session only needs the
    # CHROMEMCP_* names.
    unset PORT UPSTREAM_PORT CDP_PORT MCP_URL MCP_TOKEN_PATH MCP_CHROME_PROFILE_NAME
  else
    echo "no free claude ChromeMCP lane; continuing on the default stack" >> "$REPORT"
  fi
fi

# stream-json through the formatter so the report streams progress live
# (plain `--output-format text` stays silent until the run ends). --resume is
# safe on a fresh todo: the guard falls back to a normal start when no prior
# state exists, and preserves notes/blockers/slices when one does.
set +o pipefail  # the pipeline must complete so PIPESTATUS captures claude's exit code
"$CLAUDE" -p "/overnight-runner:start --resume $TODO_FILE" \
  --output-format stream-json --verbose \
  --permission-mode "$PERMISSION_MODE" \
  ${MCP_CONFIG_ARGS[@]+"${MCP_CONFIG_ARGS[@]}"} 2>&1 \
  | python3 "$SCRIPT_DIR/stream-report.py" \
  | tee -a "$REPORT"
CLAUDE_EXIT="${PIPESTATUS[0]}"
set -o pipefail
if [ "$CLAUDE_EXIT" -ne 0 ]; then
  echo "claude exited non-zero: $CLAUDE_EXIT" >> "$REPORT"
fi
echo "overnight-runner unattended run finished $(date -Is)" >> "$REPORT"
