# Add krew to PATH if it exists
if [ -f "${HOME}/.krew/bin" ]; then
  path+="${HOME}/.krew/bin"
fi

# Lazy load kubernetes setup to improve shell startup performance
if (( $+commands[kubectl] )); then
  __kubectl_lazy_load() {
    # Remove the lazy loading functions
    unfunction kubectl k 2>/dev/null
    
    # Load kubectl completions
    if [[ ! -f "$ZSH_CACHE_DIR/completions/_kubectl" ]]; then
      kubectl completion zsh | tee "$XDG_CACHE_HOME/completions/_kubectl" >/dev/null
      source "$XDG_CACHE_HOME/completions/_kubectl"
    else
      source "$XDG_CACHE_HOME/completions/_kubectl"
      kubectl completion zsh | tee "$XDG_CACHE_HOME/completions/_kubectl" >/dev/null &|
    fi
    
    # Load all kubernetes aliases and functions
    source "${ZDOTDIR:-$HOME/.config/zsh}/zshrc.d/kubernetes-aliases.zsh"
    
    # Call the original command with all arguments
    "$1" "${@:2}"
  }
  
  # Create lazy-loading wrapper functions
  kubectl() { __kubectl_lazy_load kubectl "$@" }
  k() { __kubectl_lazy_load kubectl "$@" }
else
  # If kubectl is not available, define k as an alias that suggests installation
  k() { echo "kubectl is not installed or not in PATH" }
fi