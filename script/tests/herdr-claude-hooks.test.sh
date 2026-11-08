#!/usr/bin/env bash
#
# Tests for the herdr-aware Claude Code hooks in home/dot_claude/hooks/:
# executable_herdr-context.sh (SessionStart) and executable_herdr-status.sh
# (PostToolUse). Both run against a fake herdr, so no real pane is touched.
#
# Run: script/tests/herdr-claude-hooks.test.sh

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
hooks=$here/../../home/dot_claude/hooks
context=$hooks/executable_herdr-context.sh
status=$hooks/executable_herdr-status.sh

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

failures=0
check() {
  local label=$1 expected=$2 actual=$3
  if [ "$expected" = "$actual" ]; then
    printf '  ok   %s\n' "$label"
  else
    printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' "$label" "$expected" "$actual"
    failures=$((failures + 1))
  fi
}

# A fake herdr that records its argv one call per line (args joined by |, so
# multi-word values stay readable) and answers `workspace get` with a label.
cat >"$work/herdr" <<'FAKE'
#!/usr/bin/env bash
(IFS='|'; echo "$*") >>"$HERDR_CALLS"
case "$1 $2" in
  'workspace get') echo '{"result":{"workspace":{"label":"demo"}}}' ;;
esac
FAKE
chmod +x "$work/herdr"

in_herdr=(HERDR_ENV=1 HERDR_PANE_ID=w3:p1 HERDR_TAB_ID=w3:t1 HERDR_WORKSPACE_ID=w3
  HERDR_BIN="$work/herdr" HERDR_CALLS="$work/calls" HERDR_STATUS_DIR="$work")

echo "herdr-context"

: >"$work/calls"
out=$(echo '{}' | env -u HERDR_ENV -u HERDR_PANE_ID HERDR_BIN="$work/herdr" HERDR_CALLS="$work/calls" "$context")
check 'outside herdr: prints nothing' '' "$out"
check 'outside herdr: no herdr calls' '' "$(cat "$work/calls")"

out=$(echo '{}' | env "${in_herdr[@]}" "$context")
check 'inside herdr: names workspace, tab and pane' \
  'herdr session context: workspace w3 ("demo"), tab w3:t1, pane w3:p1 (this pane).' \
  "$(head -n 1 <<<"$out")"
check 'inside herdr: appends the policy' '# Running inside herdr' "$(sed -n 3p <<<"$out")"

echo "herdr-status"

write_status() {
  cat >"$work/STATUS.md"
}
hook() {
  : >"$work/calls"
  printf '{"tool_input":{"file_path":"%s"}}' "$1" | env "${in_herdr[@]}" "$status"
}

write_status <<'EOF'
# fix dns
**State:** working
**Waiting on me:** nothing
EOF
hook "$work/STATUS.md"
check 'working: sets title, clears labels' \
  'pane|report-metadata|w3:p1|--source|claude-status|--agent|claude|--title|fix dns|--clear-state-labels' \
  "$(cat "$work/calls")"

hook "$work/README.md"
check 'other files are ignored' '' "$(cat "$work/calls")"

write_status <<'EOF'
# fix dns
**State:** blocked
**Waiting on me:** which zone should the record go in?
EOF
hook "$work/STATUS.md"
check 'blocked on a question: labels the stop states, no notification' \
  'pane|report-metadata|w3:p1|--source|claude-status|--agent|claude|--title|fix dns|--state-label|done=blocked: which zone should the record go in?|--state-label|idle=blocked: which zone should the record go in?' \
  "$(cat "$work/calls")"

write_status <<'EOF'
# fix dns
**State:** blocked
**Waiting on me:** run ~/src/handoff/dotfiles-dns/fix.sh
EOF
hook "$work/STATUS.md"
check 'blocked on a handoff: notifies with the request sound' \
  'notification|show|Handoff: fix dns|--body|run ~/src/handoff/dotfiles-dns/fix.sh|--sound|request' \
  "$(sed -n 2p "$work/calls")"

hook "$work/STATUS.md"
check 'same handoff again: no second notification' 1 "$(wc -l <"$work/calls" | tr -d ' ')"

write_status <<'EOF'
# fix dns
**State:** working
**Waiting on me:** nothing
EOF
hook "$work/STATUS.md"
write_status <<'EOF'
# fix dns
**State:** blocked
**Waiting on me:** run ~/src/handoff/dotfiles-dns/fix.sh
EOF
hook "$work/STATUS.md"
check 'handoff after unblocking: notifies again' 2 "$(wc -l <"$work/calls" | tr -d ' ')"

: >"$work/calls"
printf '{"tool_input":{"file_path":"%s"}}' "$work/STATUS.md" |
  env -u HERDR_ENV HERDR_BIN="$work/herdr" HERDR_CALLS="$work/calls" "$status"
check 'outside herdr: no herdr calls' '' "$(cat "$work/calls")"

if [ "$failures" -gt 0 ]; then
  echo "$failures failure(s)"
  exit 1
fi
