# zmodload zsh/zprof


if ((! $+commands[brew])); then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    brew_location="/opt/homebrew/bin/brew"
  elif [[ -x /usr/local/bin/brew ]]; then
    brew_location="/usr/local/bin/brew"
  elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    brew_location="/home/linuxbrew/.linuxbrew/bin/brew"
  elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
    brew_location="$HOME/.linuxbrew/bin/brew"
  else
    echo "No Homebrew found -- experience will be degraded"
  fi
fi

if [[ -z "$HOMEBREW_PREFIX" ]]; then
  if [[ -z $brew_location ]]; then
    if (( $+commands[brew] )); then 
      eval "$(brew shellenv)"
    fi
  else
    eval "$("$brew_location" shellenv)"
  fi
fi

unset brew_location

# This gives us completions for brew-install things
if (( $+commands[brew] )); then 
  # Cache brew prefix to avoid subprocess call on every shell startup
  if [[ -z "$HOMEBREW_ZSH_COMPLETIONS" ]]; then
    export HOMEBREW_ZSH_COMPLETIONS="$(brew --prefix)/share/zsh-completions"
  fi
  FPATH="$HOMEBREW_ZSH_COMPLETIONS":$FPATH
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Load edit-command-line for use in vi mode
autoload -U edit-command-line
zle -N edit-command-line

# Configure zsh-vi-mode before it loads
# Must be defined BEFORE loading zsh-vi-mode plugin
ZVM_INIT_MODE=sourcing  # Initialize immediately, don't wait for first input

# Tell zsh-vi-mode to keep these keybindings and not override them
# This allows fzf to manage its own keybindings
ZVM_VI_INSERT_ESCAPE_BINDKEY=jk  # Use jk for escape instead of default
# Don't let zsh-vi-mode override these keys in insert mode
function zvm_after_select_vi_mode() {
  # Do nothing - this prevents cursor shape changes that might interfere
  return 0
}

# Hooks to restore keybindings after zsh-vi-mode initializes
# Must be defined BEFORE loading zsh-vi-mode plugin

# This hook is called after init
function zvm_after_init() {
  # Bind 'v' in vicmd mode to edit-command-line
  zvm_bindkey vicmd 'v' edit-command-line
}

# Note: fzf is loaded at the very end of .zshrc after all other config
# This ensures fzf keybindings work correctly with zsh-vi-mode

zinit ice depth=1

# Add in zsh plugins
zinit light jeffreytse/zsh-vi-mode                      # Enhanced vi mode with better feedback and features
zinit light zdharma-continuum/fast-syntax-highlighting  # Faster, more feature-rich syntax highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-history-substring-search      # Search history by substring with arrow keys
zinit light Aloxaf/fzf-tab                              # Replace tab completion with fzf
zinit light hlissner/zsh-autopair                       # Auto-close quotes and brackets
zinit light MichaelAquilina/zsh-you-should-use          # Reminds you to use aliases
zinit light wfxr/forgit                                 # Interactive git commands with fzf
zinit light paulirish/git-open                          # Open GitHub/GitLab page for current repo

# Add in snippets
# zinit snippet OMZL::git.zsh  # Removed - conflicts with forgit
# zinit snippet OMZP::git      # Removed - conflicts with forgit
# zinit snippet OMZP::sudo
# zinit snippet OMZP::archlinux
# zinit snippet OMZP::aws
zinit snippet OMZP::gcloud
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
# zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit -u

zinit cdreplay -q

# Bind history-substring-search after plugins load
# This must come after zsh-history-substring-search plugin is loaded
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^[OA' history-substring-search-up
bindkey '^[OB' history-substring-search-down

if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config ${HOME}/.config/ohmyposh/ohmyposh.json)"
fi

# Sort and source all scripts in zshrd.d
for rc in "${ZDOTDIR}"/zshrc.d/*.zsh; do
  # ignore files that begin with ~
  [[ "${rc:t}" != '~'* ]] || continue
  source "$rc"
done

# Initialize fzf keybindings after all other config
# This ensures fzf bindings take precedence over zsh-vi-mode
if (( $+commands[fzf] )); then
  source <(fzf --zsh)
fi

# Load any local-to-the-host configuration
if [ -f "${HOME}/.zsh_local" ]; then
  source "${HOME}/.zsh_local"
fi

# Load secrets
if [ -f "${HOME}/.secrets" ]; then
  source "${HOME}/.secrets"
fi

# zprof
