# This function is useful
_has() {
  # Returns whether the given command is executable or aliased.
  return $( whence $1 >/dev/null )
}

add_to_path() {
  local DIR=$1
  if ! grep ":$DIR:" -q <<< ":$PATH:"; then
    export PATH=$PATH:$DIR
  fi
}

# Correct a bad $SHELL setting
if [[ $SHELL == *"bash"* ]]; then
  export SHELL=/usr/local/bin/zsh
fi

# Nicer workaround for Vim+tmux colors and mappings.
# See: https://github.com/henrik/dotfiles/commit/f8347e465fe9c4b9ff7ea211e2263d6e34ace9dd
export TERM='xterm-color'
