if type "brew" > /dev/null; then
  # For the 5.0.x Homebrew'ed zsh installation...
  # unalias run-help
  autoload run-help
  HELPDIR=/usr/local/share/zsh/help

  # Opt out of Homebrew analytics
  export HOMEBREW_NO_ANALYTICS=1

  # Cask options
  HOMEBREW_CASK_OPTS="--appdir=~/Applications"
fi
