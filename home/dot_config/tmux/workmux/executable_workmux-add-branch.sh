#!/usr/bin/env bash
printf 'Branch: '
read -r branch
[ -z "$branch" ] && exit 0
workmux add "$branch" || { echo; echo "workmux add failed. Press any key to close."; read -n 1 -s; }
