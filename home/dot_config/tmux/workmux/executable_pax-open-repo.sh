#!/usr/bin/env bash
#
# Open a repo as its own tmux session with a long-running pax lead in window 0.
#
# The session is named for the repo's basename with any persona- prefix stripped,
# matching window-name.sh -- nearly every work repo is persona-*, and the prefix
# is noise in a session list. The basename itself stays the lookup key: it
# resolves the path, keys the port registry and keys pax's session store, so
# stripping the label cannot collide persona-web with a separate web checkout.
#
# Window 0 is named "pax" and runs pi under a stable --session-id so the window
# is cheap to kill and relaunch -- the multi-hour dispatcher context lives in
# pi's session store, not the pane.
#
# Computer ports come from a persisted registry rather than a hash of the repo
# name: hashing ~20 repos into any range small enough to be memorable collides
# far more often than intuition suggests, and a registry cannot collide at all.
#
# Seams for script/tests/pax-open-repo.test.sh:
#   SRC_ROOT      -- where checkouts live (default: $HOME/src)
#   PORT_REGISTRY -- repo->port map (default: $XDG_STATE_HOME/pax/ports)
#   TMUX_BIN      -- tmux executable (default: tmux)
#   PAX_BIN       -- pax/pi executable (default: pi)
#   PAX_LIST_ONLY -- when non-empty, print "<name> <path>" per repo and exit

set -euo pipefail

src_root=${SRC_ROOT:-$HOME/src}
tmux_bin=${TMUX_BIN:-tmux}
pax_bin=${PAX_BIN:-pi}
registry=${PORT_REGISTRY:-${XDG_STATE_HOME:-$HOME/.local/state}/pax/ports}
port_base=8800
port_span=1000

# BSD find has no -printf, so strip the /.git suffix with sed instead.
list_repos() {
  find "$src_root" -maxdepth 3 -name .git -not -path '*__worktrees*' 2>/dev/null |
    sed 's|/\.git$||' | sort
}

path_for() {
  local name=$1 path
  while IFS= read -r path; do
    [ "$(basename "$path")" = "$name" ] && { printf '%s\n' "$path"; return 0; }
  done <<EOF
$(list_repos)
EOF
  return 1
}

port_for() {
  local name=$1 port
  mkdir -p "$(dirname "$registry")"
  [ -f "$registry" ] || : >"$registry"
  port=$(awk -v n="$name" '$1 == n { print $2; exit }' "$registry")
  if [ -n "$port" ]; then
    printf '%s\n' "$port"
    return 0
  fi
  port=$port_base
  while awk -v p="$port" '$2 == p { found = 1 } END { exit !found }' "$registry"; do
    port=$((port + 1))
    if [ "$port" -ge $((port_base + port_span)) ]; then
      echo "pax-open-repo: port registry exhausted at $registry" >&2
      return 1
    fi
  done
  printf '%s %s\n' "$name" "$port" >>"$registry"
  printf '%s\n' "$port"
}

focus_session() {
  local name=$1
  "$tmux_bin" switch-client -t "=$name" 2>/dev/null ||
    "$tmux_bin" attach-session -t "=$name"
}

open_repo() {
  local name=$1 path port session
  path=$(path_for "$name") || {
    echo "pax-open-repo: no repo named '$name' under $src_root" >&2
    return 1
  }
  # Label only -- every key below stays on the unstripped basename.
  session=${name#persona-}
  if "$tmux_bin" has-session -t "=$session" 2>/dev/null; then
    focus_session "$session"
    return 0
  fi
  port=$(port_for "$name") || return 1
  "$tmux_bin" new-session -d -s "$session" -c "$path" -n pax \
    "PAX_COMPUTER_PORT=$port $pax_bin --session-id pax-$name"
  focus_session "$session"
}

pick_repo() {
  # FZF_DEFAULT_OPTS sets --tmux, which makes fzf spawn its own nested tmux
  # popup for its UI. Since this script already runs inside a popup, that
  # nesting breaks (fzf exits immediately with no selection). Strip --tmux
  # for this invocation so fzf renders inline in the popup we already have.
  local opts
  opts=$(echo "${FZF_DEFAULT_OPTS:-}" | sed -E 's/--tmux(=[^ ]+)?( [a-z]+)?//')
  list_repos | sed 's|.*/||' | FZF_DEFAULT_OPTS="$opts" fzf
}

if [ -n "${PAX_LIST_ONLY:-}" ]; then
  list_repos | while IFS= read -r path; do
    printf '%s %s\n' "$(basename "$path")" "$path"
  done
  exit 0
fi

name=${1:-}
[ -n "$name" ] || name=$(pick_repo)
[ -n "$name" ] || exit 0

open_repo "$name" || {
  # Only pause when there is a tty to pause for: the popup needs the message to
  # stay on screen, but script/tests/pax-open-repo.test.sh would hang on it.
  if [ -t 0 ]; then
    echo
    echo "pax-open-repo failed. Press any key to close."
    read -r -n 1 -s
  fi
  exit 1
}
