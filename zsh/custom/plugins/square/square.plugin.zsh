if [[ -d "$HOME/Development" ]]; then
  SQUARE_HOME=$HOME/Development
fi
export SQUARE_HOME
if [[ -f "$SQUARE_HOME/config_files/square/zshrc" ]]; then
  #source $SQUARE_HOME/config_files/square/zshrc
fi

function add_to_path {
  local DIR=$1
  if ! grep ":$DIR:" -q <<< ":$PATH:"; then
    export PATH=$PATH:$DIR
  fi
}

# color grep
export GREP_OPTIONS='--color=auto -E'
GREP_COLOR='1;32'
#
# # automatically enter directories without cd
setopt auto_cd

add_to_path /usr/local/mysql/bin
add_to_path $HOME/bin
add_to_path /opt/nginx/sbin
add_to_path /opt/local/bin
add_to_path /opt/local/sbin

# Range
export RANGE_HOST=grange.sso.global.square
export RANGE_PORT=443
export RANGE_SSL=1

# Go
export GOROOT=/usr/local/go
export GOPATH="$SQUARE_HOME/go"
export GOFETCH_ALIASES="$SQUARE_HOME/config_files/config/go/aliases"
add_to_path $GOPATH/bin
add_to_path $GOROOT/bin

# Put topsoil on the path
if [[ -d "$SQUARE_HOME/topsoil/bin" ]]; then
  add_to_path $SQUARE_HOME/topsoil/bin
fi