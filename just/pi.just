set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# pi installs and updates itself. pi.dev's installer lays down a managed install
# under ~/.pi/agent/install (one directory per release, every dependency pinned
# by a lockfile), a launcher at ~/.pi/agent/bin/pi, and a symlink to that
# launcher in the first of ~/bin or ~/.local/bin on PATH. `pi update` swaps
# releases in place. These recipes drive that installer; they no longer keep an
# npm prefix of their own.
#
# What the installer leaves open is the interpreter. A release's bin is
# `#!/usr/bin/env node`, so left alone pi runs on whatever node asdf's shim picks
# in the current directory -- and dies with "No version is set for command node"
# in any repo whose pinned node isn't installed. The launcher checks one hook
# first: if ${XDG_DATA_HOME:-~/.local/share}/pi-node/current/bin/node exists, that
# directory goes on the front of PATH. link-node points it at Homebrew's node
# (brew/Brewfile), which no .tool-versions can reach.
#
# The link is machine-local and untracked: it bakes in a brew prefix that differs
# between macOS (/opt/homebrew) and Linux (/home/linuxbrew/.linuxbrew).
#
# Homebrew lives outside the environment a task runner inherits on some boxes,
# so link-node re-resolves it explicitly rather than trusting `command -v` --
# the same belt-and-braces lookup rust.just does for rustup.

pi_installer := "https://pi.dev/install.sh"
pi_launcher := "${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/bin/pi"
pi_node_link := "${XDG_DATA_HOME:-$HOME/.local/share}/pi-node/current"

# The generated wrapper from the npm-prefix layout this replaced. pi's installer
# refuses to replace a pi it doesn't own, so install clears it out of the way.
old_wrapper := "$HOME/.local/bin/pi"

# Install pi with its own installer, running on Homebrew's node
install: link-node
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -f "{{ old_wrapper }}" ] && [ ! -L "{{ old_wrapper }}" ]; then
      printf '\033[33m%s\033[0m\n' "Clearing the old pi layout out of the installer's way"
      "$REPO/script/pi-purge-legacy"
      if [ -e "{{ old_wrapper }}" ]; then
        printf '\033[31m%s\033[0m\n' "Cannot install pi -- {{ old_wrapper }} is still in the way"
        exit 1
      fi
    fi
    # Fetched whole before it runs, so a dropped download fails here instead of
    # half-executing.
    installer=$(curl -fsSL "{{ pi_installer }}")
    printf '\033[32m%s\033[0m\n' 'Install: pi'
    # The installer runs node and npm off PATH; put brew's first so pi is
    # installed by the same node it will run on.
    PATH="{{ pi_node_link }}/bin:$PATH" sh -c "$installer"

# Point pi's node hook at Homebrew's node, so no .tool-versions picks pi's interpreter
link-node:
    #!/usr/bin/env bash
    set -euo pipefail
    brew_bin=$(command -v brew 2>/dev/null || true)
    for candidate in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
      [ -n "$brew_bin" ] && break
      [ -x "$candidate" ] && brew_bin=$candidate
    done
    if [ -z "$brew_bin" ]; then
      printf '\033[31m%s\033[0m\n' "Cannot pin pi's node -- Homebrew not found"
      exit 1
    fi
    # opt/node rather than a Cellar path, so the link survives brew upgrades.
    brew_node=$("$brew_bin" --prefix)/opt/node
    if [ ! -x "$brew_node/bin/node" ]; then
      printf '\033[31m%s\033[0m\n' "Cannot pin pi's node -- brew node not installed"
      printf '\033[33m%s\033[0m\n' "Run: brew bundle --file=$REPO/brew/Brewfile"
      exit 1
    fi
    link="{{ pi_node_link }}"
    # The installer's own standalone node is a symlink here too, so repointing a
    # link is fine; anything else at this path is not ours to replace.
    if [ -e "$link" ] && [ ! -L "$link" ]; then
      printf '\033[31m%s\033[0m\n' "Cannot pin pi's node -- $link is not a symlink"
      exit 1
    fi
    [ "$(readlink "$link" 2>/dev/null || true)" != "$brew_node" ] || exit 0
    mkdir -p "$(dirname "$link")"
    ln -sfn "$brew_node" "$link"
    printf '\033[32mpi now runs on node %s (%s)\033[0m\n' "$("$link/bin/node" --version)" "$brew_node"

# Update pi and its extensions, when pi is installed
update:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ ! -x "{{ pi_launcher }}" ]; then
      if [ -f "{{ old_wrapper }}" ] && [ ! -L "{{ old_wrapper }}" ]; then
        printf '\033[31m%s\033[0m\n' "No updates to pi performed -- pi is on the old npm-prefix layout (just pi::install)"
      else
        printf '\033[31m%s\033[0m\n' 'No updates to pi performed -- pi not installed (just pi::install)'
      fi
      exit 0
    fi
    # A missing pin is worth a warning, not a stalled fan-out: pi still updates
    # and runs, just on asdf's per-directory node.
    {{ just_executable() }} --justfile "$REPO/justfile" pi::link-node ||
      printf '\033[33m%s\033[0m\n' "pi left on asdf's node -- see above"
    printf '\033[32m%s\033[0m\n' 'Update: pi and its extensions'
    # stdin is closed so an unattended `just update` cannot stall on a prompt, and
    # --no-approve keeps this repo's own .pi/ settings out of a global update.
    "{{ pi_launcher }}" update --all --no-approve </dev/null

# Remove pi installs that predate pi's own installer (one-shot)
purge-legacy:
    @"$REPO/script/pi-purge-legacy"

# Preview what purge-legacy would remove
purge-legacy-preview:
    @"$REPO/script/pi-purge-legacy" --preview
