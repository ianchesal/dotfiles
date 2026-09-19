# Dotfiles task runner.
#
# chezmoi deploys the configs; this owns the "update everything" fan-out and the
# handful of tool tasks that have no chezmoi equivalent. It replaced a Rakefile
# so the repo no longer needs a Ruby runtime (plus bundler and gems) just to
# shell out -- see docs/chezmoi-workflows.md.
#
# `just --list --list-submodules` is the old `rake -T`.
# Per-tool recipes live in just/<tool>.just and are addressed as `just brew::update`.

set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# Repo root. Module recipes run with their own directory as the working
# directory, so this is how they reach script/ and each other. It is what the
# root() helper did in the Rakefile, and it survives being invoked from
# anywhere, including `just --justfile <path>`.
export REPO := justfile_directory()

# Every module file lives in just/. A tool's directory now holds only its real
# assets (brew/Brewfile, nvim/, winterm/settings.json) -- the old
# <tool>/<tool>.rake colocation stopped meaning anything when chezmoi moved the
# configs to home/dot_config/<tool>/. Module recipes run with just/ as their
# working directory, so reach everything through $REPO.
mod asdf 'just/asdf.just'
mod brew 'just/brew.just'
mod claude 'just/claude.just'
mod gcloud 'just/gcloud.just'
mod gem 'just/gem.just'
mod git 'just/git.just'
mod nvim 'just/nvim.just'
mod ohmyposh 'just/ohmyposh.just'
mod pi 'just/pi.just'
mod rust 'just/rust.just'
mod shell 'just/shell.just'
mod tmux 'just/tmux.just'
mod winterm 'just/winterm.just'
mod ytdlp 'just/ytdlp.just'

[private]
default:
    @just --list --list-submodules

# Update everything that can be (safely) updated. nvim::update is deliberately excluded --
# dfu runs it only on dads-gaming-pc (see docs/chezmoi-workflows.md) to avoid racing
# concurrent `just nvim::update` runs into conflicting pins.json commits.
update: brew::update asdf::update rust::update claude::update pi::update git::update gcloud::update ytdlp::update gem::cleanup ohmyposh::check-update

# Install the asdf-managed runtimes, Rust toolchain first
install-runtimes: rust::install asdf::install

# Check that this machine is correctly provisioned (read-only)
doctor:
    @"$REPO/script/doctor"

# Lint every shell script and check justfile formatting
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    shellcheck --severity=warning \
      script/asdf-prune script/gem-cleanup script/nvim-commit script/doctor \
      script/brew-trust script/pi-purge-legacy \
      script/verify-chezmoi-assumptions.sh home/run_once_*.sh \
      script/tests/*.test.sh bootstrap/*.sh \
      home/dot_bashrc home/dot_bash_profile home/dot_config/bash/bashrc.sh \
      home/dot_config/bash/bashrc.d/*.bash
    python3 -c 'import ast, sys; ast.parse(open(sys.argv[1]).read())' script/gen-claude-completions.py
    just --fmt --check --justfile "$REPO/justfile"

# Run the shell script tests (no nvim required -- this is what CI runs)
test-scripts:
    #!/usr/bin/env bash
    set -euo pipefail
    for t in "$REPO"/script/tests/*.test.sh; do "$t"; done

# Run the shell script tests and the nvim machinery tests
test: test-scripts
    #!/usr/bin/env bash
    set -euo pipefail
    for t in "$REPO"/nvim/tests/*_spec.lua; do
      echo "nvim: ${t##*/}"
      nvim --headless -u NONE -l "$t"
    done
