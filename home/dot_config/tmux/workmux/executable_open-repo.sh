#!/usr/bin/env bash
#
# Open a repo as its own tmux session: one window, one bare shell at the repo
# root. There is no per-repo pax lead any more -- one machine-wide lead lives in
# the "pax" session (pax-lead.sh) and every repo dispatches to it.
#
# The session is named for the repo's basename with any persona- prefix stripped,
# matching window-name.sh -- nearly every work repo is persona-*, and the prefix
# is noise in a session list. The basename itself stays the lookup key that
# resolves the path. The one exception is a repo that would strip to "pax":
# that name belongs to the lead, so persona-pax keeps its full basename rather
# than dropping you into the dispatcher.
#
# Seams for script/tests/open-repo.test.sh:
#   SRC_ROOT            -- where checkouts live (default: $HOME/src)
#   TMUX_BIN            -- tmux executable (default: tmux)
#   OPEN_REPO_LIST_ONLY -- when non-empty, print "<name> <path>" per repo and exit

set -euo pipefail

src_root=${SRC_ROOT:-$HOME/src}
tmux_bin=${TMUX_BIN:-tmux}
lead_session=pax

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
    echo "open-repo: no repo named '$name' under $src_root" >&2
    return 1
  }
  session=${name#persona-}
  [ "$session" != "$lead_session" ] || session=$name
  if "$tmux_bin" has-session -t "=$session" 2>/dev/null; then
    focus_session "$session"
    return 0
  fi
  # Checked explicitly: open_repo is called from a `||` context, which disables
  # errexit inside it, so an unchecked tmux failure would still exit 0.
  "$tmux_bin" new-session -d -s "$session" -c "$path" || {
    echo "open-repo: could not create session '$session'" >&2
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

if [ -n "${OPEN_REPO_LIST_ONLY:-}" ]; then
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
  # stay on screen, but script/tests/open-repo.test.sh would hang on it.
  if [ -t 0 ]; then
    echo
    echo "open-repo failed. Press any key to close."
    read -r -n 1 -s
  fi
  exit 1
}
