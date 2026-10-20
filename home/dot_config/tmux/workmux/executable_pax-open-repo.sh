#!/usr/bin/env bash
#
# Open a repo as its own tmux session with a single shell window at the repo
# root.
#
# The session is named for the repo's basename with any persona- prefix stripped,
# matching window-name.sh -- nearly every work repo is persona-*, and the prefix
# is noise in a session list. The basename itself stays the lookup key, so
# stripping the label cannot collide persona-web with a separate web checkout.
#
# This used to open a long-running pax lead in a second window, with a stable
# --session-id and a per-repo PAX_COMPUTER_PORT from a port registry. That was
# dropped in October 2026 while pax is out of use; the git history has it if it
# comes back. Re-opening an existing session only focuses it.
#
# Seams for script/tests/pax-open-repo.test.sh:
#   SRC_ROOT      -- where checkouts live (default: $HOME/src)
#   TMUX_BIN      -- tmux executable (default: tmux)
#   PAX_LIST_ONLY -- when non-empty, print "<name> <path>" per repo and exit

set -euo pipefail

src_root=${SRC_ROOT:-$HOME/src}
tmux_bin=${TMUX_BIN:-tmux}

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

focus_session() {
  local name=$1
  "$tmux_bin" switch-client -t "=$name" 2>/dev/null ||
    "$tmux_bin" attach-session -t "=$name"
}

open_repo() {
  local name=$1 path session
  path=$(path_for "$name") || {
    echo "pax-open-repo: no repo named '$name' under $src_root" >&2
    return 1
  }
  # Label only -- the lookup above stays on the unstripped basename.
  session=${name#persona-}
  if "$tmux_bin" has-session -t "=$session" 2>/dev/null; then
    focus_session "$session"
    return 0
  fi
  # Checked explicitly: open_repo is called from a `||` context, which disables
  # errexit inside it, so an unchecked tmux failure here would still exit 0.
  "$tmux_bin" new-session -d -s "$session" -c "$path" -n shell || {
    echo "pax-open-repo: could not create session '$session'" >&2
    return 1
  }
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
