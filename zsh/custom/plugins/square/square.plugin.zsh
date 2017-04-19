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
alias grep='grep --color=auto -E'
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
export GOPATH="${HOME}/Development/go"
if [[ -d "${HOME}/Development/config_files/config/go/aliases" ]]; then
  export GOFETCH_ALIASES="${HOME}/Development/config_files/config/go/aliases"
fi
add_to_path $GOPATH/bin

# Put topsoil on the path
if [[ -d "$SQUARE_HOME/topsoil/bin" ]]; then
  add_to_path $SQUARE_HOME/topsoil/bin
fi

# The next line updates PATH for the Google Cloud SDK.
if [ -f '~/google-cloud-sdk/path.zsh.inc' ]; then source '~/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '~/google-cloud-sdk/completion.zsh.inc' ]; then source '~/google-cloud-sdk/completion.zsh.inc'; fi

# For keeping disk clean
function get-free-disk-space() {
  df -k / | tail -n 1 | awk '{ print $4 }'
}

function as-gb() {
  read num
  echo $(echo "scale=2;$num/1048576" | bc)Gi
}

function clean-logs() {
  before=$(get-free-disk-space)
  set -x
  /bin/rm -f ~/Development/web/log/*.log
  /bin/rm -f ~/Development/log/development/*
  /bin/rm -f ~/Development/log/*
  /bin/rm -f ~/Development/jumbotron/log/*
  /bin/rm -f /usr/local/var/log/nginx/*.log
  set +x
  after=$(get-free-disk-space)
  diff=$(echo $(expr $before - $after) | as-gb)
  echo "Cleaned up $diff"
}
