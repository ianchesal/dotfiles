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

# For PowerLevel10k configuration
POWERLEVEL9K_CONFIG_FILE=$ZDOTDIR/p10k.zsh

# define environment for non-login, non-interactive shells which don't source .zprofile
if [[ ( "$SHLVL" -eq 1 && ! -o LOGIN ) && -s $ZDOTDIR/.zprofile ]]; then
  source $ZDOTDIR/.zprofile
fi
