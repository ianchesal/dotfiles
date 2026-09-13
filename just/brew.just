set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

export HOMEBREW_NO_ENV_HINTS := "1"
export HOMEBREW_NO_ASK := "1"

# Update Homebrew-installed packages
update:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v brew >/dev/null; then
      printf '\033[34m%s\033[0m\n' 'Skipping: Homebrew update -- no brew command found'
      exit 0
    fi
    printf '\033[32m%s\033[0m\n' 'Update: Homebrew'
    pinned=$(brew list --pinned --quiet 2>/dev/null || true)
    outdated=$(brew outdated --quiet || true)
    # oh-my-posh is deliberately excluded: ohmyposh::check-update only reports a
    # waiting update, so a prompt change is never a surprise mid-run.
    keep=$(printf '%s\n' "$outdated" | grep -vxF 'oh-my-posh' || true)
    if [ -n "$pinned" ]; then
      keep=$(printf '%s\n' "$keep" | grep -vxF "$pinned" || true)
    fi
    keep=$(printf '%s\n' "$keep" | grep -v '^$' || true)
    if [ -z "$keep" ]; then
      printf '\033[34m%s\033[0m\n' 'No outdated formulas to upgrade'
      exit 0
    fi
    printf '\033[32mUpgrading formulas: %s\033[0m\n' "$(printf '%s' "$keep" | tr '\n' ' ')"
    if [ -n "$pinned" ]; then
      printf '\033[34mSkipping pinned packages: %s\033[0m\n' "$(printf '%s' "$pinned" | paste -sd, - | sed 's/,/, /g')"
    fi
    printf '%s\n' "$keep" | xargs brew upgrade --force
    brew cleanup

# Trust the third-party taps and formulae declared in brew/trusted
trust:
    @"$REPO/script/brew-trust"
