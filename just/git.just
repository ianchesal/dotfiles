set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# Install any missing gh CLI extensions (safe to re-run)
install-extensions:
    #!/usr/bin/env bash
    set -euo pipefail
    command -v gh >/dev/null || { echo 'gh is not installed' >&2; exit 1; }
    gh auth status >/dev/null 2>&1 || { echo 'gh is not authenticated; run: gh auth login' >&2; exit 1; }
    installed="$(gh extension list)"
    failed=0
    for ext in gennaro-tedesco/gh-f dlvhdr/gh-dash github/gh-stack; do
      if grep -qwF "$ext" <<<"$installed"; then
        echo "gh extension $ext already installed"
      else
        echo "Installing gh extension $ext"
        gh extension install "$ext" || { echo "Failed to install $ext" >&2; failed=1; }
      fi
    done
    exit "$failed"

# Install any missing gh CLI extensions, then upgrade them all
update:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v gh >/dev/null; then
      # This runs mid fan-out: being logged out or a failed install must not stop the recipes after it.
      # `gh extension upgrade` exits 4 when logged out, so that has to be skipped as well.
      if ! gh auth status >/dev/null 2>&1; then
        printf '\033[33m%s\033[0m\n' "gh is not logged in; skipping extensions -- run 'gh auth login', then 'just git::update'"
        exit 0
      fi
      just --justfile "$REPO/justfile" git::install-extensions \
        || printf '\033[33m%s\033[0m\n' 'Some gh extensions failed to install; continuing'
      printf '\033[32m%s\033[0m\n' 'Updating gh extensions'
      gh extension upgrade --all
    fi
