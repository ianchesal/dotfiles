# Forwarded SSH agent: one stable socket path per SSH session
#
# A forwarded agent's socket (/tmp/ssh-XXXX/agent.NNN) changes on every login,
# but shells inside a long-lived tmux session keep whichever one they started
# with, so after a reconnect they point at a dead socket. On each SSH login that
# carries a live forwarded agent, repoint ~/.ssh/agent-forwarded.sock at it and
# use that fixed path instead: every pane, old or new, follows the latest
# connection. Outside SSH sessions this does nothing.
#
# ~/.ssh/config's 1Password block and zshrc.d/1password.zsh both defer to a
# forwarded agent in an SSH session; `test -S` follows the symlink, so they keep
# working with the stable path. Skipped on work and gcw boxes, which keep their
# own ~/.ssh (the flag file and marker dir are tested directly).

if [[ -n "${SSH_CONNECTION:-}" && -S "${SSH_AUTH_SOCK:-}" ]] \
  && [[ ! -f "$HOME/.work_machine" && ! -d /etc/workstation-startup.d ]]; then
  _fwd_sock="$HOME/.ssh/agent-forwarded.sock"
  if [[ "$SSH_AUTH_SOCK" != "$_fwd_sock" ]] && ln -sfn "$SSH_AUTH_SOCK" "$_fwd_sock" 2>/dev/null; then
    export SSH_AUTH_SOCK="$_fwd_sock"
  fi
  unset _fwd_sock
fi
