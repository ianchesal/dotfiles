# zmodload zsh/zprof

# Disable compinit security checks for insecure directories
export ZSH_DISABLE_COMPFIX=true

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

zinit ice depth=1

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
# zinit snippet OMZP::archlinux
# zinit snippet OMZP::aws
zinit snippet OMZP::gcloud
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config ${HOME}/.config/ohmyposh/ohmyposh.json)"
fi

# Sort and source all scripts in zshrd.d
for rc in "${ZDOTDIR}"/zshrc.d/*.zsh; do
  # ignore files that begin with ~
  [[ "${rc:t}" != '~'* ]] || continue
  source "$rc"
done

# Load any local-to-the-host configuration
if [ -f "${HOME}/.zsh_local" ]; then
  source "${HOME}/.zsh_local"
fi

# Load secrets
if [ -f "${HOME}/.secrets" ]; then
  source "${HOME}/.secrets"
fi

# zprof
