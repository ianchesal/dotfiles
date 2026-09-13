#!/usr/bin/env bash
# ~/.claude.json is a SIBLING of ~/.claude, not a file inside it, so it is
# outside chezmoi's target set entirely. Preserves the chmod that
# claude/claude.rake used to perform.
set -euo pipefail
f="$HOME/.claude.json"
if [ -f "$f" ]; then
  mode="$(stat -c '%a' "$f" 2>/dev/null || stat -f '%Lp' "$f")"
  if [ "$mode" != "600" ]; then
    chmod 600 "$f"
    echo "Set $f permissions to 600"
  fi
fi
