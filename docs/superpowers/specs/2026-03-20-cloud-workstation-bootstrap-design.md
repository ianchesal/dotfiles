# Cloud Workstation Bootstrap Script Design

**Date:** 2026-03-20
**File:** `bootstrap/cloud-workstation.sh`

## Overview

A single idempotent bash script that sets up a Google Cloud Workstation from a fresh state to a fully configured development environment using the dotfiles repo. The repo is assumed to already be cloned at `~/src/dotfiles`.

## Goals

- Fully automate the 8-step cloud workstation setup
- Idempotent: safe to re-run if any step fails partway through
- Each step skips itself (with a `[SKIP]` message) if already completed
- Clear progress output so the operator can see what's happening

## Non-Goals

- Cloning the dotfiles repo (assumed present at `~/src/dotfiles`)
- Setting up tools other than what's in the Brewfile
- Installing non-Ruby asdf runtimes (just Ruby 3.3.9 for the bootstrap, to get `rake` working)

## Script: `bootstrap/cloud-workstation.sh`

### Header & Helpers

- Shebang: `#!/usr/bin/env bash`
- Strict mode: `set -euo pipefail`
- `DOTFILES=$HOME/src/dotfiles`
- `log()` helper prints colored `==> Step N: <description>` banners
- Steps print `[SKIP]` when already done, `[RUN]` when executing

### Steps

**Step 1 — Install Homebrew**
- Guard: `command -v brew`
- Action: run official Homebrew install script via curl
- After install or if already present: source brew shellenv using the known Linux path:
  `eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"` to get `brew` in PATH for subsequent steps
- Target is Linux (Google Cloud Workstation); macOS paths not required

**Step 2 — `brew bundle install`**
- Guard: `brew bundle check --file=$DOTFILES/brew/Brewfile --no-lock`
- Action: `brew bundle install --file=$DOTFILES/brew/Brewfile --no-lock`
- Known limitation: if the Brewfile gains new entries after a prior run, the check guard passes and new entries are silently skipped. This is acceptable for this use case; `brew bundle install` is itself idempotent so re-running the full script corrects it.

**Step 3 — Add Homebrew zsh to `/etc/shells`**
- Guard: `grep -qF "$(brew --prefix)/bin/zsh" /etc/shells`
- Action: `echo "$(brew --prefix)/bin/zsh" | sudo tee -a /etc/shells`
- Note: sudo is passwordless on cloud workstation

**Step 4 — Change default shell to Homebrew zsh**
- Guard: check `/etc/passwd` entry for current user rather than `$SHELL`, since `$SHELL` reflects the shell at login time and won't show the new value until the next login session even after a successful `chsh`
- Action: `chsh -s "$(brew --prefix)/bin/zsh"`
- Note: the new shell takes effect on next login; `$SHELL` in the current session will remain unchanged — do not add a post-step verification that reads `$SHELL`

**Step 5 — Source asdf into the current script shell**
- No guard — unconditionally source `. "$(brew --prefix asdf)/libexec/asdf.sh"`
- This makes `asdf` available for Steps 6+ within the script
- Note: the path `libexec/asdf.sh` is correct for asdf installed via Homebrew; verify against the installed formula if asdf is upgraded

**Step 6 — Install Ruby 3.3.9 via asdf**
- Guard: `asdf list ruby 2>/dev/null | grep -qE '^\s*3\.3\.9$'` (anchored to avoid matching superset versions like `3.3.90`)
- Actions:
  1. `asdf plugin add ruby || true`
  2. `asdf install ruby 3.3.9`
  3. `asdf set -u ruby 3.3.9` (set as user-level default in `~/.tool-versions` so `rake` is available in subsequent steps)

**Step 7 — Set up zsh configuration (`rake zsh`)**
- Guard: both `~/.config/zsh` symlinks to `$DOTFILES/zsh` AND `~/.zshenv` symlinks to `$DOTFILES/zsh/.zshenv` (checking the two symlinks that `rake zsh` creates; the directory creation steps are safe to repeat)
- Action: `cd "$DOTFILES" && rake zsh`

**Step 8 — Install kitty terminfo**
- Guard: `infocmp xterm-kitty &>/dev/null`
- Action: fetch `kitty.terminfo` from the kitty GitHub repo and pipe to `tic -x -`
- URL: `https://raw.githubusercontent.com/kovidgoyal/kitty/master/terminfo/kitty.terminfo`

## File Location

`bootstrap/cloud-workstation.sh` — alongside the existing `bootstrap/centos.sh`

## Error Handling

- `set -euo pipefail` causes the script to exit on any unhandled error
- Steps that are expected to be partially idempotent use `|| true` (e.g., `asdf plugin add`)
- The user can re-run the script after fixing any failure; completed steps will be skipped
