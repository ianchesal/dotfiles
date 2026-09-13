set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# Windows Terminal's settings.json lives outside $HOME on the Windows side of a
# WSL2 box, so chezmoi cannot deploy it -- this copy is the only way it lands.
settings_file := '/mnt/c/Users/ianch/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json'

# Install the Windows Terminal settings (WSL2 only)
install:
    #!/usr/bin/env bash
    set -euo pipefail
    dest={{ quote(settings_file) }}
    if [ ! -d "$(dirname "$dest")" ]; then
      printf '\033[33m%s\033[0m\n' 'Skipping: Windows Terminal settings -- not a WSL2 box'
      exit 0
    fi
    cp --force --verbose "$REPO/winterm/settings.json" "$dest"
