#!/bin/bash

# Launch gh-dash with the config that matches this machine.
# Work machines (~/.work_machine exists) get config-work.yml, which scopes "My
# Pull Requests" and "Assigned to Me" to the persona-id org. Everywhere else
# falls through to the default config.yml that gh-dash finds on its own.
#
# The flag is a file, not $WORK_MACHINE, because this runs inside a tmux popup:
# a popup inherits tmux's environment, captured when the server started, not the
# environment of the shell you're sitting in.

set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/gh-dash"

if [ -f "${HOME}/.work_machine" ]; then
    exec gh dash --config "${config_dir}/config-work.yml" "$@"
fi

exec gh dash "$@"
