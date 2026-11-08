set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# herdr ships its own agent skill (`herdr --skill`), written for the installed
# version. It is machine-local and untracked -- same category as the _claude
# completion spec -- so this writes it straight into ~/.claude/skills/herdr,
# which chezmoi leaves alone because ~/.claude/skills carries no exact_ prefix.

# Install or refresh herdr's agent skill for Claude Code
skill:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v herdr >/dev/null; then
      printf '\033[33m%s\033[0m\n' 'herdr not found, skipping its Claude skill'
      exit 0
    fi
    dest=$HOME/.claude/skills/herdr/SKILL.md
    new=$(herdr --skill)
    if [ -f "$dest" ] && [ "$(cat "$dest")" = "$new" ]; then
      printf '\033[32m%s\033[0m\n' 'herdr Claude skill already current'
      exit 0
    fi
    mkdir -p "$(dirname "$dest")"
    printf '%s\n' "$new" >"$dest"
    printf '\033[32mWrote herdr Claude skill to %s\033[0m\n' "$dest"
