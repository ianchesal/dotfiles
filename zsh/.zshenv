#
# .zshenv
#

# XDG basedirs (https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
export XDG_CONFIG_HOME=~/.config
export XDG_CACHE_HOME=~/.cache
export XDG_DATA_HOME=~/.local/share
export XDG_RUNTIME_DIR=~/.xdg

# ZDOTDIR givs an alternate home for zsh rather than $HOME
export ZDOTDIR=$XDG_CONFIG_HOME/zsh

# WSL2: trim the inherited Windows PATH.
#
# Windows interop appends ~19 /mnt/c directories to PATH. Those sit on the 9p
# filesystem, where proving a command does NOT exist costs ~70ms, because zsh
# has to walk every PATH entry to be sure. Worse, each later `path=`/`path+=`
# invalidates zsh's command hash and forces another full walk -- our startup
# does that several times over, so this alone was ~375ms of shell startup.
#
# Keep the Windows dirs whose executables are resolved BY BARE NAME by tools we
# don't control, so their behaviour is unchanged:
#   /mnt/c/Windows             explorer.exe  -- tmux/open-url.sh
#   .../System32               clip.exe      -- nvim clipboard, and the vendored
#                                               tmux-yank + tmux-fzf-url plugins,
#                                               which probe for it by name and
#                                               must not be patched (TPM resets them)
#   .../WindowsPowerShell/v1.0 powershell.exe -- nvim clipboard paste
# That trims the per-miss cost from ~70ms to ~19ms.
#
# Everything else on the Windows PATH (code, winget, ...) stays runnable by bare
# name via the command_not_found_handler below, which pays the 9p cost only when
# a command actually misses.
#
# This must run before $ZDOTDIR/.zprofile is sourced below: .zprofile probes
# $commands for lesspipe, which populates the whole hash table.
if [[ -n "$WSL_DISTRO_NAME" || -n "$WSL_INTEROP" ]]; then
  # Capture the full Windows PATH once; children inherit it and skip this.
  # Note the intermediate array: joining the nested form directly, as
  # "${(j.:.)${(M)path:#/mnt/*}}", loses the array-ness and yields an empty
  # string, which silently leaves the fallback handler with nothing to search.
  if [[ -z "$WSL_WIN_PATH" ]]; then
    typeset -a _wsl_win_dirs
    _wsl_win_dirs=( ${(M)path:#/mnt/*} )
    export WSL_WIN_PATH="${(j.:.)_wsl_win_dirs}"
    unset _wsl_win_dirs
  fi

  # Idempotent: re-running strips then re-adds the same three, and -U dedupes.
  path=(
    ${path:#/mnt/*}
    /mnt/c/Windows
    /mnt/c/Windows/System32
    /mnt/c/Windows/System32/WindowsPowerShell/v1.0
  )
  typeset -gU path

  # Fall back to the full Windows PATH for anything not found above.
  command_not_found_handler() {
    local cmd="$1" d
    for d in ${(s.:.)WSL_WIN_PATH}; do
      [[ -x "$d/$cmd" ]] && { "$d/$cmd" "${@:2}"; return $? }
      [[ -x "$d/$cmd.exe" ]] && { "$d/$cmd.exe" "${@:2}"; return $? }
    done
    print -u2 "zsh: command not found: $cmd"
    return 127
  }
fi

# define environment for non-login, non-interactive shells which don't source .zprofile
if [[ ("$SHLVL" -eq 1 && ! -o LOGIN) && -s $ZDOTDIR/.zprofile ]]; then
  source $ZDOTDIR/.zprofile
fi

# Load npq wrapper for all zsh shells
if [ -f /usr/local/persona/npq-wrapper.sh ]; then
  source /usr/local/persona/npq-wrapper.sh
fi

# Disable the wrapper if requested
if [ -f "$HOME/.disable-npq" ]; then
  unset -f npm yarn pnpm 2>/dev/null
fi
