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
