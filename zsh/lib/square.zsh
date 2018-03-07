if [[ -d "$HOME/Development" ]]; then
  SQUARE_HOME=$HOME/Development
fi
export SQUARE_HOME
#if [[ -f "$SQUARE_HOME/config_files/square/zshrc" ]]; then
  #source $SQUARE_HOME/config_files/square/zshrc
#fi

#add_to_path /usr/local/mysql/bin
#add_to_path /opt/nginx/sbin
#add_to_path /opt/local/bin
#add_to_path /opt/local/sbin

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

# Snowflake
export SNOWSQL_ACCOUNT="square"

# Put topsoil on the path
if [[ -d "$SQUARE_HOME/topsoil/bin" ]]; then
  add_to_path $SQUARE_HOME/topsoil/bin
fi

# For keeping disk clean
get-free-disk-space() {
  df -k / | tail -n 1 | awk '{ print $4 }'
}

as-gb() {
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
