# 1Password SSH agent
#
# ~/.1password/agent.sock is the one agent path on every platform: native Linux
# 1Password creates it, chezmoi symlinks it to the group-container socket on
# macOS, and on WSL the relay below serves it from the Windows named pipe.
# ~/.ssh/config points ssh at it only when the socket exists (Match exec); this
# file additionally exports SSH_AUTH_SOCK so ssh-add and other agent clients
# see 1Password too.
#
# Does nothing on work or gcw boxes (they keep their own ~/.ssh and agent):
# the flag file and marker dir are tested directly, never an exported variable.

if [[ ! -f "$HOME/.work_machine" && ! -d /etc/workstation-startup.d ]]; then
  _op_sock="$HOME/.1password/agent.sock"

  # True when an agent answers on $1. ssh-add -l exits 0 (keys) or 1 (no keys)
  # after reaching an agent, 2 when it could not connect.
  _op_sock_live() {
    [[ -S "$1" ]] || return 1
    # timeout(1) bounds a wedged relay; it exits 124 on expiry, which counts as
    # not live. macOS has no timeout, so fall back to a bare ssh-add.
    if (( $+commands[timeout] )); then
      SSH_AUTH_SOCK="$1" timeout 2 ssh-add -l >/dev/null 2>&1
    else
      SSH_AUTH_SOCK="$1" ssh-add -l >/dev/null 2>&1
    fi
    (( $? != 2 && $? != 124 ))
  }

  # Full path to the Windows-side npiperelay.exe, or failure. It is normally NOT
  # on PATH here: dot_zshenv trims the Windows PATH for startup speed, and a tmux
  # server started before the install keeps the old one anyway. So also look
  # where winget puts it. Every probe of /mnt/c is slow (9p), which is why this
  # only runs when the relay actually needs starting -- about once per boot.
  _op_find_npiperelay() {
    local c
    for c in ${commands[npiperelay.exe]-} \
      /mnt/c/Users/*/AppData/Local/Microsoft/WinGet/{Links,Packages/albertony.npiperelay_*}/npiperelay.exe(N); do
      [[ -x "$c" ]] && { print -r -- "$c"; return 0; }
    done
    return 1
  }

  # WSL: relay the Windows 1Password pipe onto the unix socket. Needs
  # npiperelay.exe on the Windows side (winget install albertony.npiperelay) and
  # socat/flock/setsid here. flock serialises shells started together (tmux
  # restoring panes) so they cannot unlink each other's socket; the liveness check
  # is repeated inside the lock. socat must not inherit the lock fd, or the lock
  # would be held for the relay's whole life. socat's EXEC splits on spaces, so
  # this assumes no space in the npiperelay.exe path (winget's paths have none).
  if [[ -r /proc/sys/kernel/osrelease && "$(</proc/sys/kernel/osrelease)" == *[Mm]icrosoft* ]] \
    && (( $+commands[socat] && $+commands[flock] && $+commands[setsid] )); then
    mkdir -p -m 700 "$HOME/.1password"
    if ! _op_sock_live "$_op_sock" && _op_relay=$(_op_find_npiperelay); then
      (
        flock -w 5 9 || exit 0
        _op_sock_live "$_op_sock" && exit 0
        rm -f "$_op_sock"
        setsid socat "UNIX-LISTEN:$_op_sock,fork" \
          "EXEC:$_op_relay -ei -s //./pipe/openssh-ssh-agent,nofork" </dev/null >/dev/null 2>&1 9>&- &
        for _i in {1..20}; do [[ -S "$_op_sock" ]] && break; sleep 0.05; done
      ) 9>"$HOME/.1password/.relay.lock"
    fi
  fi

  # Point agent clients at 1Password -- unless this is an SSH session that
  # already carries a forwarded agent, which wins.
  if [[ -S "$_op_sock" ]] && ! [[ -n "${SSH_CONNECTION:-}" && -S "${SSH_AUTH_SOCK:-}" ]]; then
    export SSH_AUTH_SOCK="$_op_sock"
  fi
fi

unset _op_sock _op_relay _i
unfunction _op_sock_live _op_find_npiperelay 2>/dev/null
