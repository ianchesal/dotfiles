#!/usr/bin/env bash
#
# Ctrl-h/j/k/l for herdr: the herdr half of vim-tmux-navigator.
#
# Bound in config.toml as a detached custom command. When the focused pane is
# running vim/nvim (or fzf, as vim-tmux-navigator does), the key is passed
# through so the editor moves between its own splits; nvim calls
# `herdr pane focus` itself when it hits an edge (see
# nvim/lua/plugins/vim-tmux-navigator.lua). Anywhere else herdr moves focus.
#
# Usage: nav.sh left|down|up|right

set -euo pipefail

direction=${1:?usage: nav.sh left|down|up|right}
case $direction in
  left) key=ctrl+h ;;
  down) key=ctrl+j ;;
  up) key=ctrl+k ;;
  right) key=ctrl+l ;;
  *) echo "nav.sh: bad direction: $direction" >&2 && exit 2 ;;
esac

# herdr injects its binary path, but a brew upgrade under a running server
# leaves it pointing at a deleted Cellar path -- fall back to PATH.
herdr=${HERDR_BIN_PATH:-herdr}
[ -x "$herdr" ] || herdr=herdr

pane=${HERDR_ACTIVE_PANE_ID:-}
if [ -z "$pane" ]; then
  exec "$herdr" pane focus --current --direction "$direction"
fi

# Same process-name match as vim-tmux-navigator's is_vim.
editor_re='^g?\.?(view|l?n?vim?x?|fzf)(diff)?(-wrapped)?$'
names=$("$herdr" pane process-info --pane "$pane" 2>/dev/null |
  jq -r '.result.process_info.foreground_processes[].name' 2>/dev/null || true)

if grep -Eq "$editor_re" <<<"$names"; then
  exec "$herdr" pane send-keys "$pane" "$key"
fi
exec "$herdr" pane focus --pane "$pane" --direction "$direction"
