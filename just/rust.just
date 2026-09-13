set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# rustup lives in ~/.cargo/bin, which zshrc.d/rust.zsh puts on PATH for
# interactive shells but which is usually absent from the environment a task
# runner inherits -- so every recipe below falls back to that path explicitly
# rather than trusting a bare `command -v` lookup.

# Install rustup and the stable Rust toolchain
install:
    #!/usr/bin/env bash
    set -euo pipefail
    rustup=$(command -v rustup 2>/dev/null || true)
    if [ -z "$rustup" ] && [ -x "$HOME/.cargo/bin/rustup" ]; then
      rustup=$HOME/.cargo/bin/rustup
    fi
    if [ -n "$rustup" ]; then
      printf '\033[33mrustup already installed at %s, skipping the installer\033[0m\n' "$rustup"
      exit 0
    fi
    printf '\033[32m%s\033[0m\n' 'Install: rustup'
    # --no-modify-path keeps the installer out of the managed .zshrc; it still
    # writes ~/.cargo/env, which zshrc.d/rust.zsh sources to put ~/.cargo/bin
    # on PATH.
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs |
      sh -s -- -y --no-modify-path --default-toolchain stable

# Update rustup and every toolchain it manages
update:
    #!/usr/bin/env bash
    set -euo pipefail
    rustup=$(command -v rustup 2>/dev/null || true)
    if [ -z "$rustup" ] && [ -x "$HOME/.cargo/bin/rustup" ]; then
      rustup=$HOME/.cargo/bin/rustup
    fi
    if [ -z "$rustup" ]; then
      printf '\033[31m%s\033[0m\n' 'No updates to rust performed -- rustup not found'
      exit 0
    fi
    # Keep a rustup update from stalling an unattended `just update`. Long text
    # like a toolchain's release notes gets handed to $PAGER, which is `less` in
    # an interactive shell and then sits on the alternate screen waiting for a
    # keypress. Point PAGER at cat so that text just scrolls past, and
    # belt-and-braces a pager that ignores PAGER by appending -F (quit if it
    # fits one screen) and -X (leave the alternate screen alone) to whatever
    # LESS the caller had -- later less options win. stdin is closed too, so
    # nothing else can block on input.
    export PAGER=cat MANPAGER=cat GIT_PAGER=cat
    export LESS="${LESS:-} -F -X"
    printf '\033[32m%s\033[0m\n' 'Update: rustup'
    "$rustup" self update </dev/null
    printf '\033[32m%s\033[0m\n' 'Update: rust toolchains'
    "$rustup" update </dev/null

# Uninstall rustup and every toolchain it manages
[confirm("Uninstall rustup and every toolchain it manages? [y/N]")]
uninstall:
    #!/usr/bin/env bash
    set -euo pipefail
    rustup=$(command -v rustup 2>/dev/null || true)
    if [ -z "$rustup" ] && [ -x "$HOME/.cargo/bin/rustup" ]; then
      rustup=$HOME/.cargo/bin/rustup
    fi
    if [ -z "$rustup" ]; then
      printf '\033[33m%s\033[0m\n' 'Nothing to uninstall -- rustup not found'
      exit 0
    fi
    "$rustup" self uninstall -y
