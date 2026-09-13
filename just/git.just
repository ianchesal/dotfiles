set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# Upgrade installed gh CLI extensions
update:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v gh >/dev/null; then
      printf '\033[32m%s\033[0m\n' 'Updating gh extensions'
      gh extension upgrade --all
    fi
