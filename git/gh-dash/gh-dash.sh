#!/bin/bash

# Launch gh-dash with the config that matches this machine.
# Work machines (WORK_MACHINE=true, exported from ~/.zsh_local) get
# config-work.yml, which scopes "My Pull Requests" and "Assigned to Me" to the
# persona-id org. Everywhere else falls through to the default config.yml that
# gh-dash finds on its own.

set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/gh-dash"

if [ "${WORK_MACHINE:-}" = "true" ]; then
    exec gh dash --config "${config_dir}/config-work.yml" "$@"
fi

exec gh dash "$@"
