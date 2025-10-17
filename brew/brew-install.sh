#!/usr/bin/env bash

set -e

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Detect brew location and add to PATH for this session
if [[ -x /opt/homebrew/bin/brew ]]; then
  # macOS Apple Silicon
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  # macOS Intel
  eval "$(/usr/local/bin/brew shellenv)"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  # Linux
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
else
  echo "Error: Could not find brew installation" >&2
  exit 1
fi

# Now brew should be in PATH, run bundle
cd "$(dirname "$0")"
brew bundle
