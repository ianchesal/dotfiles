#!/usr/bin/env bash
cmd="$1"
[ -z "$cmd" ] && exit 1

# FZF_DEFAULT_OPTS sets --tmux, which makes fzf spawn its own nested tmux
# popup for its UI. Since this script already runs inside a popup, that
# nesting breaks (fzf exits immediately with no selection). Strip --tmux
# for this invocation so fzf renders inline in the popup we already have.
FZF_DEFAULT_OPTS=$(echo "$FZF_DEFAULT_OPTS" | sed -E 's/--tmux(=[^ ]+)?( [a-z]+)?//')

selection=$(workmux list | tail -n +2 | FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS" fzf)
[ -z "$selection" ] && exit 0

branch=$(echo "$selection" | awk '{print $1}')
workmux "$cmd" "$branch" || {
  echo
  echo "workmux $cmd failed. Press any key to close."
  read -n 1 -s
}
