if (( $+commands[brew] )); then
  # For the 5.0.x Homebrew'ed zsh installation...
  # unalias run-help
  autoload run-help
  HELPDIR=${HOMEBREW_PREFIX}/share/zsh/help

  # Opt out of Homebrew analytics
  export HOMEBREW_NO_ANALYTICS=1

  # Cask options
  HOMEBREW_CASK_OPTS="--appdir=~/Applications"

  # Gnu Util installed in homebrew?
  # Cache brew prefix to avoid subprocess call on every shell startup
  if [[ -z "$HOMEBREW_GNUTILS_PATH" ]]; then
    export HOMEBREW_GNUTILS_PATH="$(brew --prefix)/opt/grep/libexec/gnubin"
  fi
  if [ -d "$HOMEBREW_GNUTILS_PATH" ]; then
    path=($HOMEBREW_GNUTILS_PATH "$path[@]")
  fi
fi
