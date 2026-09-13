set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# Report (but do not apply) a waiting oh-my-posh update
check-update:
    #!/usr/bin/env bash
    set -euo pipefail
    command -v brew >/dev/null || exit 0
    outdated=$(brew outdated --verbose oh-my-posh || true)
    if [ -z "$outdated" ]; then
      printf '\033[34m%s\033[0m\n' 'No update to oh-my-posh found'
      exit 0
    fi
    # Loud on purpose: the prompt is the one thing a surprise upgrade would
    # change under you every time you open a shell, so it stays opt-in.
    printf '\n\n'
    printf '\033[32m%s\033[0m\n' "$(printf '*%.0s' {1..80})"
    printf '\033[1;33m%s\033[0m\n' 'ATTENTION: oh-my-posh update available!'
    printf '\033[33mDetails: %s\033[0m\n' "$outdated"
    printf '\033[33m%s\033[0m\n' "Run 'just ohmyposh::update' to update"
    printf '\033[32m%s\033[0m\n' "$(printf '*%.0s' {1..80})"
    printf '\n'

# Update oh-my-posh via Homebrew
update:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v brew >/dev/null; then
      printf '\033[32m%s\033[0m\n' 'Update: oh-my-posh'
      brew upgrade oh-my-posh
      brew cleanup
    else
      printf '\033[34m%s\033[0m\n' 'Skipping: oh-my-posh update -- no brew command found'
    fi
