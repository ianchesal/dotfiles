#!/usr/bin/env bash
#
# Tests for home/dot_config/herdr/executable_nav.sh. Drives the script against a
# fake herdr that models one column of three panes (p1 on top, p3 at the
# bottom), so focus moves and wraps without a running server.
#
# Run: script/tests/herdr-nav.test.sh

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
subject=$here/../../home/dot_config/herdr/executable_nav.sh

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

# A fake herdr that records its argv one call per line. The focused pane lives
# in $FOCUS_FILE. `pane focus` moves within the column and reports `changed`
# as the real one does; left/right are always edges. $ZOOMED marks the layout
# zoomed, $FG names the pane's foreground process.
mkdir -p "$work/bin"
cat >"$work/bin/herdr" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >>"$HERDR_CALLS"
case "$1 $2" in
  'pane process-info')
    printf '{"result":{"process_info":{"foreground_processes":[{"name":"%s"}]}}}\n' "${FG:-zsh}"
    ;;
  'pane focus')
    shift 2
    from=$(cat "$FOCUS_FILE")
    while [ $# -gt 0 ]; do
      case $1 in
        --pane) from=$2 && shift ;;
        --direction) dir=$2 && shift ;;
      esac
      shift
    done
    n=${from#p}
    case $dir in
      up) [ "$n" -gt 1 ] && n=$((n - 1)) ;;
      down) [ "$n" -lt 3 ] && n=$((n + 1)) ;;
    esac
    changed=false
    [ "p$n" != "$from" ] && changed=true && echo "p$n" >"$FOCUS_FILE"
    printf '{"result":{"focus":{"changed":%s,"focused_pane_id":"%s","layout":{"zoomed":%s}}}}\n' \
      "$changed" "$(cat "$FOCUS_FILE")" "${ZOOMED:-false}"
    ;;
esac
FAKE
chmod +x "$work/bin/herdr"

# run <focused pane> <nav.sh args...>; the focused pane is also the active one
# a keybinding sees.
run() {
  local start=$1
  shift
  : >"$work/calls"
  echo "$start" >"$work/focus"
  HERDR_CALLS=$work/calls FOCUS_FILE=$work/focus HERDR_BIN_PATH=$work/bin/herdr \
    HERDR_ACTIVE_PANE_ID=$start "$subject" "$@" >"$work/out" 2>"$work/err"
}
focused() { cat "$work/focus"; }

echo "herdr-nav"

# --- an ordinary move ---------------------------------------------------------
run p1 down
check "moves to the neighbour" "p2" "$(focused)"

# --- wrapping at an edge ------------------------------------------------------
run p3 down
check "down from the bottom wraps to the top" "p1" "$(focused)"
run p1 up
check "up from the top wraps to the bottom" "p3" "$(focused)"
run p2 left
check "a lone column stays put on left" "p2" "$(focused)"

# --- a zoomed pane never walks the layout -------------------------------------
ZOOMED=true run p3 down
check "zoomed: no wrap" "p3" "$(focused)"

# --- editors get the key ------------------------------------------------------
FG=nvim run p3 down
check "nvim: the key is passed through" "1" "$(grep -c '^pane send-keys p3 ctrl+j$' "$work/calls" || true)"
check "nvim: focus is untouched" "p3" "$(focused)"
FG=nvim run p3 --no-passthrough down
check "--no-passthrough moves even over nvim" "p1" "$(focused)"
check "--no-passthrough sends no keys" "0" "$(grep -c '^pane send-keys' "$work/calls" || true)"

# --- bad input ----------------------------------------------------------------
if run p1 sideways; then status=0; else status=$?; fi
check "rejects an unknown direction" "2" "$status"

if [ "$failures" -gt 0 ]; then
  echo "$failures failure(s)"
  exit 1
fi
