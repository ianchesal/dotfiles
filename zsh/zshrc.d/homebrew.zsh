# For the 5.0.x Homebrew'ed zsh installation...
# unalias run-help
autoload run-help
HELPDIR=${HOMEBREW_PREFIX}/share/zsh/help

# Opt out of Homebrew analytics
export HOMEBREW_NO_ANALYTICS=1

# Cask options
HOMEBREW_CASK_OPTS="--appdir=~/Applications"

# Completions
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh-completions:$(brew --prefix)/share/zsh/site-functions:$FPATH

  autoload -Uz compinit
  compinit
fi

# Gnu Util installed in homebrew?
GNUTILS_PATH="$(brew --prefix)/opt/grep/libexec/gnubin"
if [ -d "$GNUTILS_PATH" ]; then
  export PATH="$GNUTILS_PATH":$PATH
fi
