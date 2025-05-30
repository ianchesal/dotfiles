# zoxide: a smarter cd
# See: https://github.com/ajeetdsouza/zoxide
# Lazy load zoxide to improve shell startup performance
if (( $+commands[zoxide] )); then
  __zoxide_lazy_load() {
    # Remove the lazy loading functions
    unfunction cd z __zoxide_z 2>/dev/null
    
    # Initialize zoxide
    eval "$(zoxide init --cmd cd zsh)"
    
    # Call the original command with all arguments
    "$1" "${@:2}"
  }
  
  # Define a custom function that combines zoxide with pushd
  # so I can do popd to get back to whence I came from.
  z() {
    if [ "$#" -eq 0 ]; then
      # If no arguments, behave like cd to home directory with pushd
      pushd ~
    else
      # Use zoxide to find the directory and pushd to it
      pushd "$(zoxide query "$@")" > /dev/null
    fi
  }

  alias cd="z"
fi
