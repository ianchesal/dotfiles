HISTFILE=~/.zsh_history
setopt APPEND_HISTORY
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_EXPIRE_DUPS_FIRST
setopt EXTENDED_HISTORY
setopt SHARE_HISTORY

alias h='history'

function hs
{
    history | rg -N $*
}

alias hsi='hs -i'
