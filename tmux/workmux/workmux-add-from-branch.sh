#!/usr/bin/env bash
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Not a git repository"
  echo "Press any key to close."
  read -n 1 -s
  exit 1
fi

# FZF_DEFAULT_OPTS sets --tmux, which makes fzf spawn its own nested tmux
# popup for its UI. Since this script already runs inside a popup, that
# nesting breaks (fzf exits immediately with no selection). Strip --tmux
# for this invocation so fzf renders inline in the popup we already have.
FZF_DEFAULT_OPTS=$(echo "$FZF_DEFAULT_OPTS" | sed -E 's/--tmux(=[^ ]+)?( [a-z]+)?//')

selection=$(git branch --format='%(refname:short)' | FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS" fzf)
[ -z "$selection" ] && exit 0

workmux add "$selection" || {
  echo
  echo "workmux add failed. Press any key to close."
  read -n 1 -s
}
