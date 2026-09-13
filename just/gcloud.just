set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# Update the gcloud CLI components
update:
    #!/usr/bin/env bash
    set -euo pipefail
    gcloud_path=$(command -v gcloud 2>/dev/null || true)
    if [ "$gcloud_path" = /usr/bin/gcloud ]; then
      printf '\033[33m%s\033[0m\n' 'Skipping gcloud components update -- system-installed gcloud should be managed by system package manager'
    elif [ -n "${CLOUDSDK_HOME:-}" ] && [ -d "$CLOUDSDK_HOME" ]; then
      printf '\033[32m%s\033[0m\n' 'Update: gcloud components'
      gcloud components update --quiet
    else
      printf '\033[31m%s\033[0m\n' 'No updates to gcloud components performed -- no gcloud CLI found'
    fi
