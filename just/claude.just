set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# On Debian/WSL2 the claude-code deb owns /usr/bin/claude and apt drives its
# updates. Running the curl installer or `claude update` on such a box creates a
# competing copy, and because npm's global prefix can sit inside the asdf node
# tree, that copy lands ahead of /usr/bin on PATH and shadows the deb.

# Install claude, unless apt already owns it
install:
    #!/usr/bin/env bash
    set -euo pipefail
    source "$REPO/claude/apt-claude.sh"
    if deb_version=$(apt_claude_version) && [ -n "$deb_version" ]; then
      printf '\033[33mclaude-code %s is apt managed, skipping the installer\033[0m\n' "$deb_version"
      printf '\033[33m%s\033[0m\n' 'Install or upgrade it with: sudo apt update && sudo apt upgrade claude-code'
      exit 0
    fi
    curl -fsSL https://claude.ai/install.sh | bash

# Tighten ~/.claude.json to 0600 if it has drifted
permissions:
    #!/usr/bin/env bash
    set -euo pipefail
    settings=$HOME/.claude.json
    if [ ! -e "$settings" ]; then
      printf '\033[33mNo %s file found, skipping permissions check\033[0m\n' "$settings"
      exit 0
    fi
    mode=$(stat -c '%a' "$settings" 2>/dev/null || stat -f '%Lp' "$settings")
    if [ "$mode" != 600 ]; then
      chmod 600 "$settings"
      printf '\033[32mSet %s permissions to 600\033[0m\n' "$settings"
    fi

# Update claude, regenerating zsh completions when the version moves
update: permissions
    #!/usr/bin/env bash
    set -euo pipefail
    source "$REPO/claude/apt-claude.sh"
    deb_version=$(apt_claude_version)
    if [ -n "$deb_version" ]; then
      printf '\033[32mclaude-code %s is apt managed, updating via apt\033[0m\n' "$deb_version"
      sudo apt-get update
      sudo apt-get install --only-upgrade -y claude-code
      new_version=$(apt_claude_version)
      if [ -n "$new_version" ] && [ "$new_version" != "$deb_version" ]; then
        printf '\033[33mclaude updated %s -> %s, regenerating completions...\033[0m\n' "$deb_version" "$new_version"
        "$REPO/script/gen-claude-completions.py"
      else
        printf '\033[32mclaude-code already up to date (%s)\033[0m\n' "$deb_version"
      fi
    elif command -v claude >/dev/null; then
      printf '\033[32m%s\033[0m\n' 'Update: claude'
      old_version=$(claude --version 2>/dev/null || true)
      claude update
      new_version=$(claude --version 2>/dev/null || true)
      if [ "$old_version" != "$new_version" ]; then
        printf '\033[33mclaude updated %s -> %s, regenerating completions...\033[0m\n' "$old_version" "$new_version"
        "$REPO/script/gen-claude-completions.py"
      fi
    else
      printf '\033[31m%s\033[0m\n' 'No updates to claude components -- claude not found'
    fi

# Regenerate ~/.config/zsh/completions/_claude from `claude --help`
gen-completions:
    @"$REPO/script/gen-claude-completions.py"
