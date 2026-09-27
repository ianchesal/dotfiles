# tmux overwrites SHELL in every pane it spawns with the value of its
# `default-shell` option -- even when the pane runs an explicit command
# like `tmux split-window -h 'bash -l'`. default-shell is derived from
# the login shell, so on these machines a bash pane comes up announcing
# SHELL=.../zsh. bash never corrects this itself: it sets SHELL only
# when it is *unset*, and even then it copies /etc/passwd rather than the
# binary actually running. Same story under `su`, `sudo -s` and
# `docker exec`. Claim it here so anything that shells out via $SHELL
# (vim `:shell`, less `!cmd`, fzf, tmux popups) gets the shell you are
# actually sitting in. $BASH is bash's own full path to itself.
[[ -n "${BASH:-}" ]] && export SHELL="$BASH"

export EDITOR="${EDITOR:-vim}"
export PAGER="${PAGER:-less}"
export LESS="${LESS:--R}"

# A probe inspired by the zsh config's intent (find brew reliably
# across install locations) but not a trim of its implementation --
# the zsh config splices known bin dirs onto $path directly and
# assumes `brew` is already resolvable; this checks known absolute
# `brew` binary locations and evals `brew shellenv` on the first hit,
# so it works even when this shell reaches its config before
# Homebrew's own shell init has run (root shells, minimal environments).
if ! command -v brew >/dev/null 2>&1; then
  for brew_candidate in /opt/homebrew/bin/brew /usr/local/bin/brew \
    /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
    if [[ -x "$brew_candidate" ]]; then
      eval "$("$brew_candidate" shellenv)"
      break
    fi
  done
  unset brew_candidate
fi

# Personal and XDG bin dirs, as zsh's 03-env.zsh adds them. Don't lean
# on ~/.profile for these: it only runs for login shells, macOS has none,
# and Debian's skel version skips ~/.local/bin if it didn't exist at login.
# Appended (matching zsh) and deduplicated, since a nested bash inherits
# a PATH that may already carry them.
for bin_dir in "$HOME/bin" "$HOME/.local/bin"; do
  if [[ -d "$bin_dir" && ":$PATH:" != *":$bin_dir:"* ]]; then
    PATH="$PATH:$bin_dir"
  fi
done
unset bin_dir
export PATH
