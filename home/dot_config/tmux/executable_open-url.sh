#!/usr/bin/env bash
# Cross-platform URL opener for tmux-fzf-url
# Supports macOS, WSL2, and native Linux

url="$1"

if [[ "$(uname -s)" == "Darwin" ]]; then
  open "$url"
elif grep -qi microsoft /proc/version 2>/dev/null; then
  if command -v wslview &>/dev/null; then
    wslview "$url"
  else
    explorer.exe "$url"
  fi
else
  xdg-open "$url"
fi

exit 0
