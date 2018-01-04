# Functions to activate/deactivate Continuum Analytics
# Anaconda Python distribution by manipulating the $PATH.
# Got this from here: https://gist.github.com/esc/4967965
export ANACONDA_PATH="$HOME/anaconda/bin"

function have_anaconda(){
    [[ -n $path[(r)$ANACONDA_PATH] ]]
}

function anaconda_on(){
    if have_anaconda ; then
        print "Anaconda already activated"
    else
        export PATH=$ANACONDA_PATH:$PATH
    fi
}

function anaconda_off(){
    if ! have_anaconda ; then
        print "Anaconda not found on PATH"
    else
        path[$path[(i)$ANACONDA_PATH]]=()
    fi
}
