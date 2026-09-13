set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# Update yt-dlp
update:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v yt-dlp >/dev/null; then
      printf '\033[32m%s\033[0m\n' 'Updating yt-dlp'
      yt-dlp -U
    fi
