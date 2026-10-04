# Forwarded SSH agent: one stable socket path per SSH session
#
# A forwarded agent's socket (/tmp/ssh-XXXX/agent.NNN) changes on every login,
# but shells inside a long-lived tmux session keep whichever one they started
# with, so after a reconnect they point at a dead socket. On each SSH login that
# carries a live forwarded agent, repoint ~/.ssh/agent-forwarded.sock at it and
# use that fixed path instead: every pane, old or new, follows the latest
# connection. Outside SSH sessions this does nothing.
#
# Last login wins, so a short-lived second login (a quick `ssh tranquility` to
# test a key) takes the link and leaves it dangling when it exits, while the
# long-lived session that owns the tmux server is still connected. A precmd hook
# notices the dead link and repoints it at the newest live forwarded socket this
# user owns, so every pane heals at its next prompt.
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

if [[ "${SSH_AUTH_SOCK:-}" == "$HOME/.ssh/agent-forwarded.sock" ]] \
  && [[ ! -f "$HOME/.work_machine" && ! -d /etc/workstation-startup.d ]]; then
  _ssh_agent_heal() {
    [[ -S "$SSH_AUTH_SOCK" ]] && return 0
    local sock
    # sshd's per-login sockets: owned by us (U), sockets only (=), newest first (om)
    for sock in /tmp/ssh-*/agent.*(N=Uom); do
      # exit 2 means nothing is listening; 0 or 1 is a live agent
      SSH_AUTH_SOCK="$sock" ssh-add -l >/dev/null 2>&1
      (( $? != 2 )) || continue
      ln -sfn "$sock" "$SSH_AUTH_SOCK" 2>/dev/null
      return 0
    done
  }
  autoload -U add-zsh-hook
  add-zsh-hook precmd _ssh_agent_heal
fi
