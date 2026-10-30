#!/usr/bin/env bash
#
# Open a repo as its own herdr workspace with a shell at the repo root -- the
# herdr twin of ../tmux/workmux/pax-open-repo.sh (tmux's prefix+w "open repo").
#
# Bound in config.toml as a popup. fzf picks a checkout under ~/src; if a
# workspace is already open on that checkout it is focused, otherwise a new one
# is created there. The label drops a persona- prefix, as pax-open-repo.sh does.
#
# Seams for script/tests/herdr-open-repo.test.sh:
#   SRC_ROOT  -- where checkouts live (default: $HOME/src)
#   HERDR_BIN -- herdr executable (default: $HERDR_BIN_PATH, else herdr on PATH)

set -euo pipefail

src_root=${SRC_ROOT:-$HOME/src}

# herdr injects its binary path, but a brew upgrade under a running server
# leaves it pointing at a deleted Cellar path -- fall back to PATH.
herdr=${HERDR_BIN:-${HERDR_BIN_PATH:-herdr}}
[ -x "$herdr" ] || herdr=herdr

# Paths relative to src_root, so two checkouts sharing a basename stay distinct.
# BSD find has no -printf, so strip the prefix and /.git suffix with sed.
list_repos() {
  find "$src_root" -maxdepth 3 -name .git -not -path '*__worktrees*' 2>/dev/null |
    sed -e "s|^$src_root/||" -e 's|/\.git$||' | sort
}

pick_repo() {
  # FZF_DEFAULT_OPTS sets --tmux; if herdr itself runs inside tmux, fzf would
  # try to open a tmux popup of its own. Render inline in herdr's popup instead.
  local opts
  opts=$(echo "${FZF_DEFAULT_OPTS:-}" | sed -E 's/--tmux(=[^ ]+)?( [a-z]+)?//')
  list_repos | FZF_DEFAULT_OPTS="$opts" fzf --prompt 'repo> '
}

open_repo() {
  local path=$1 name label existing
  [ -e "$path/.git" ] || {
    echo "open-repo: no repo at $path" >&2
    return 1
  }
  name=$(basename "$path")
  label=${name#persona-}
  # herdr records a workspace's checkout only once it has worktrees of its own;
  # until then the label is the only handle, as the session name is in tmux.
  existing=$("$herdr" workspace list |
    jq -r --arg p "$path" --arg l "$label" '.result.workspaces[]
      | select(.worktree.checkout_path == $p or (.worktree == null and .label == $l))
      | .workspace_id' | head -n 1)
  if [ -n "$existing" ]; then
    "$herdr" workspace focus "$existing" >/dev/null
  else
    "$herdr" workspace create --cwd "$path" --label "$label" --focus >/dev/null
  fi
}

rel=${1:-}
[ -n "$rel" ] || rel=$(pick_repo) || exit 0
[ -n "$rel" ] || exit 0

open_repo "$src_root/$rel" || {
  # Only pause when there is a tty to pause for: the popup needs the message to
  # stay on screen, but the test would hang on it.
  if [ -t 0 ]; then
    echo
    echo "open-repo failed. Press any key to close."
    read -r -n 1 -s
  fi
  exit 1
}
