# Make sure go is in the path
if (( ! $+commands[go] )); then
  if [ -d '/usr/local/go/bin' ]; then
    path+=('/usr/local/go/bin')
    export PATH
  fi
fi
