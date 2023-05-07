#
# environment
#

### variables
SHELL_SESSIONS_DISABLE=1
KEYTIMEOUT=1
export EDITOR="vim"
export VISUAL="vim"

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

# Preferred editor for local and remote sessions
# (Yes, I know it's vim in both cases...)
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='vim'
fi

export GREP_COLOR='1;32'
export LSCOLOR="Gxfxcxdxbxegedabagacad"

# I forget what this does...
export COPYFILE_DISABLE=true

# HISTORY CONFIG
HISTFILE=~/.local/share/zsh_history
HISTSIZE=10000
SAVEHIST=10000
HISTDUP=erase               # Erase duplicates in the history file
setopt    appendhistory     # Append history to the history file (no overwriting)
setopt    sharehistory      # Share history across terminals
setopt    incappendhistory  # Immediately append to the history file, not just when a term is killed

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

# VI MODE
# autoload -z edit-command-line
# le -N edit-command-line
# bindkey -M vicmd v edit-command-line
