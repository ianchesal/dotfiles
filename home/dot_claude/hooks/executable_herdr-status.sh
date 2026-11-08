#!/usr/bin/env bash
#
# Claude Code PostToolUse hook (Write|Edit|MultiEdit): when claude writes a
# STATUS.md inside a herdr pane, mirror it into herdr's sidebar, and notify Ian
# when it stops on a MacBook handoff.
#
#   - the `# <task name>` heading becomes the pane title
#   - `**State:** blocked` labels the pane "blocked: <Waiting on me>" for the
#     done/idle states herdr shows once claude stops; any other state clears it
#   - blocked on a ~/src/handoff script fires a herdr notification with the
#     request sound -- herdr itself only sees a finished turn there. The text
#     notified last is cached per pane, so rewriting STATUS.md with the same
#     handoff doesn't notify twice
#
# STATUS.md format is the one ~/.claude/CLAUDE.md defines. Outside herdr, or for
# any other file, it does nothing. It must never fail the tool call: every
# error path exits 0.
#
# Seams for script/tests/herdr-claude-hooks.test.sh:
#   HERDR_BIN        -- herdr executable (default: $HERDR_BIN_PATH, else herdr on PATH)
#   HERDR_STATUS_DIR -- where the last-notified cache lives (default: $TMPDIR)

set -uo pipefail

input=$(cat 2>/dev/null) || exit 0

[ "${HERDR_ENV:-}" = 1 ] || exit 0
pane=${HERDR_PANE_ID:-}
[ -n "$pane" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

file=$(jq -r '.tool_input.file_path // empty' <<<"$input" 2>/dev/null) || exit 0
[ "$(basename -- "${file:-x}")" = STATUS.md ] || exit 0
[ -f "$file" ] || exit 0

# herdr injects its binary path, but a brew upgrade under a running server
# leaves it pointing at a deleted Cellar path -- fall back to PATH.
herdr=${HERDR_BIN:-${HERDR_BIN_PATH:-herdr}}
[ -x "$herdr" ] || herdr=herdr

# The value after a `**Field:**` marker, trimmed.
field() {
  sed -n "s/^\*\*$1:\*\*[[:space:]]*//p" "$file" | head -n 1 | sed 's/[[:space:]]*$//'
}

task=$(sed -n 's/^# *//p' "$file" | head -n 1 | sed 's/[[:space:]]*$//')
state=$(field State | awk '{print tolower($1)}')
waiting=$(field 'Waiting on me')
# Labels share a narrow sidebar column.
short=$waiting
[ "${#short}" -le 48 ] || short="${short:0:47}…"

meta=(pane report-metadata "$pane" --source claude-status --agent claude)
if [ -n "$task" ]; then meta+=(--title "$task"); else meta+=(--clear-title); fi
if [ "$state" = blocked ]; then
  meta+=(--state-label "done=blocked: $short" --state-label "idle=blocked: $short")
else
  meta+=(--clear-state-labels)
fi
"$herdr" "${meta[@]}" >/dev/null 2>&1 || true

cache_dir=${HERDR_STATUS_DIR:-${TMPDIR:-/tmp}}
cache=$cache_dir/herdr-status-${pane//[^A-Za-z0-9_-]/_}.last
if [ "$state" = blocked ] && [[ $waiting == *src/handoff/* ]]; then
  if [ "$(cat "$cache" 2>/dev/null)" != "$waiting" ]; then
    "$herdr" notification show "Handoff: ${task:-claude}" --body "$waiting" --sound request >/dev/null 2>&1 || true
    printf '%s' "$waiting" >"$cache" 2>/dev/null || true
  fi
else
  rm -f "$cache" 2>/dev/null || true
fi
exit 0
