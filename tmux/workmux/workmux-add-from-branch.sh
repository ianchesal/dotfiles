#!/usr/bin/env bash
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Not a git repository"
  echo "Press any key to close."
  read -n 1 -s
  exit 1
fi

selection=$(git branch --format='%(refname:short)' | fzf)
[ -z "$selection" ] && exit 0

workmux add "$selection" || { echo; echo "workmux add failed. Press any key to close."; read -n 1 -s; }
