alias h='history'

function hs
{
    history | rg -N $*
}

alias hsi='hs -i'
