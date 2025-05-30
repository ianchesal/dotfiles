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
  
  # Create lazy-loading wrapper functions for zoxide commands
  # Note: Avoiding 'zi' since it conflicts with zinit alias
  cd() { __zoxide_lazy_load cd "$@" }
  z() { __zoxide_lazy_load z "$@" }
fi
