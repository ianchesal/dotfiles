#!/usr/bin/env bash
#
# Ctrl-h/j/k/l for herdr: the herdr half of vim-tmux-navigator.
#
# Bound in config.toml as a detached custom command. When the focused pane is
# running vim/nvim (or fzf, as vim-tmux-navigator does), the key is passed
# through so the editor moves between its own splits; nvim calls this script
# with --no-passthrough itself when it hits an edge (see
# nvim/lua/plugins/vim-tmux-navigator.lua). Anywhere else herdr moves focus.
#
# Focus wraps like tmux's select-pane: at the bottom edge, down lands on the
# top-most pane of the same column. herdr has no wrap option, so on an edge the
# script walks the opposite way until that stops moving.
#
# Usage: nav.sh [--no-passthrough] left|down|up|right

set -euo pipefail

passthrough=1
if [ "${1:-}" = --no-passthrough ]; then
  passthrough=0
  shift
fi

direction=${1:?usage: nav.sh [--no-passthrough] left|down|up|right}
case $direction in
  left) key=ctrl+h opposite=right ;;
  down) key=ctrl+j opposite=up ;;
  up) key=ctrl+k opposite=down ;;
  right) key=ctrl+l opposite=left ;;
  *) echo "nav.sh: bad direction: $direction" >&2 && exit 2 ;;
esac

# herdr injects its binary path, but a brew upgrade under a running server
# leaves it pointing at a deleted Cellar path -- fall back to PATH.
herdr=${HERDR_BIN_PATH:-herdr}
[ -x "$herdr" ] || herdr=herdr

# Moves focus one pane from $1 (a pane id, or --current) towards $2 and prints
# "<changed> <zoomed> <focused pane id>"; prints nothing if herdr fails.
step() {
  local from=(--pane "$1")
  [ "$1" = --current ] && from=(--current)
  "$herdr" pane focus "${from[@]}" --direction "$2" 2>/dev/null |
    jq -r '.result.focus | "\(.changed) \(.layout.zoomed) \(.focused_pane_id)"' 2>/dev/null || true
}

focus() {
  local changed zoomed next
  read -r changed zoomed next <<<"$(step "$1" "$direction")"
  # Moved, failed, or zoomed (the walk would shuffle focus behind the zoom).
  [ "$changed" = false ] && [ "$zoomed" = false ] || return 0
  # On the edge: walk back across the layout. Each hop starts from the pane the
  # last one landed on -- --current would keep naming the calling pane. The
  # bound stops a misbehaving server from looping forever.
  local at=$1 hops=0
  while read -r changed zoomed next <<<"$(step "$at" "$opposite")" &&
    [ "$changed" = true ] && [ "$hops" -lt 50 ]; do
    at=$next
    hops=$((hops + 1))
  done
}

pane=${HERDR_ACTIVE_PANE_ID:-}
if [ -z "$pane" ]; then
  focus --current
  exit 0
fi

if [ "$passthrough" = 1 ]; then
  # Same process-name match as vim-tmux-navigator's is_vim.
  editor_re='^g?\.?(view|l?n?vim?x?|fzf)(diff)?(-wrapped)?$'
  names=$("$herdr" pane process-info --pane "$pane" 2>/dev/null |
    jq -r '.result.process_info.foreground_processes[].name' 2>/dev/null || true)

  if grep -Eq "$editor_re" <<<"$names"; then
    exec "$herdr" pane send-keys "$pane" "$key"
  fi
fi
focus "$pane"
