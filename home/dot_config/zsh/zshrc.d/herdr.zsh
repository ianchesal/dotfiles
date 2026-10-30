#
# herdr machine label
#
# Tags the herdr workspace this shell runs in with the machine it runs on, as
# workspace metadata `host`. herdr draws a saved machine with the *local*
# client's theme, so a remote box can't recolor anything itself -- but the
# local sidebar can style a `$host` token per value (see the [ui.sidebar.spaces]
# rows in herdr/config.toml.tmpl), which is what marks tranquility's and gcw's
# workspaces apart from local ones.
#
# Runs on the server side: every pane shell herdr starts carries
# HERDR_WORKSPACE_ID and HERDR_SOCKET_PATH for its own server. Re-reporting the
# same value on each new pane is harmless and re-labels workspaces after a
# server restart. Backgrounded and silenced so shell start never waits on it.
#
# The gcw test is machine.zsh's detector, inlined because this file loads first.

if [[ -n "${HERDR_WORKSPACE_ID:-}" ]] && (( $+commands[herdr] )); then
  if [[ -d /etc/workstation-startup.d ]]; then
    _herdr_host=gcw
  else
    _herdr_host="${HOST%%.*}"
  fi
  herdr workspace report-metadata "$HERDR_WORKSPACE_ID" \
    --source dotfiles-host --token "host=${_herdr_host}" &>/dev/null &!
  unset _herdr_host
fi
