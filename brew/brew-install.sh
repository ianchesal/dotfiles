#!/usr/bin/env bash

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew tap Homebrew/bundle
cd "$(dirname "$0")"
brew bundle
