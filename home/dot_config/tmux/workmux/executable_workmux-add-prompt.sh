#!/usr/bin/env bash
printf 'Prompt: '
read -r prompt
[ -z "$prompt" ] && exit 0
workmux add -A -p "$prompt" || { echo; echo "workmux add failed. Press any key to close."; read -n 1 -s; }
