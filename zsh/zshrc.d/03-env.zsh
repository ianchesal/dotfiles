#
# environment
#

### variables
SHELL_SESSIONS_DISABLE=1
KEYTIMEOUT=1

if type nvim> /dev/null; then
  export EDITOR="nvim"
  export VISUAL="nvim"
else
  export EDITOR="vim"
  export VISUAL="vim"
fi

if (( ! $+commands[brew] )); then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    brew_location="/opt/homebrew/bin/brew"
  elif [[ -x /usr/local/bin/brew ]]; then
    brew_location="/usr/local/bin/brew"
  elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    brew_location="/home/linuxbrew/.linuxbrew/bin/brew"
  elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
    brew_location="$HOME/.linuxbrew/bin/brew"
  else
    return
  fi
fi

if [[ -z "$HOMEBREW_PREFIX" ]]; then
  if [[ -z $brew_location ]]; then
    eval "$(brew shellenv)"
  else
    eval "$("$brew_location" shellenv)"
  fi
fi

unset brew_location

# export GREP_COLOR='1;32'
# export GREP_COLORS='mt=1;32'
export LSCOLOR="Gxfxcxdxbxegedabagacad"

# For Terminal.app
export CLICOLOR=1

# I forget what this does...
export COPYFILE_DISABLE=true

# HISTORY CONFIG
HISTFILE=~/.local/share/zsh_history
# Mostly this is configured in zsh/zshrc.d/zephyr.zsh

# My bin directory
path+="$HOME/bin"

# Language
# export LC_COLLATE=en_US.UTF-8
# export LC_CTYPE=en_US.UTF-8
# export LC_MESSAGES=en_US.UTF-8
# export LC_MONETARY=en_US.UTF-8
# export LC_NUMERIC=en_US.UTF-8
# export LC_TIME=en_US.UTF-8
# export LC_ALL=en_US.UTF-8
# export LANG=en_US.UTF-8
# export LANGUAGE=en_US.UTF-8
# export LESSCHARSET=utf-8
