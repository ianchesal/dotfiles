# My fish shell configuration
# I've found https://github.com/jorgebucaran/fish-shell-cookbook incredibly
# useful for guiding my setup here.

# BOOTSTRAP
# Bootstrap Fisherman if it's not present
# See: https://github.com/fisherman/fisherman
if not functions -q fisher
  echo "Installing fisher for the first time..." >&2
  set -q XDG_CONFIG_HOME; or set XDG_CONFIG_HOME ~/.config
  curl https://git.io/fisher --create-dirs -sLo $XDG_CONFIG_HOME/fish/functions/fisher.fish
  fisher
  curl -Lo ~/.config/fish/functions/fisher.fish --create-dirs https://git.io/fisher
  # Now install all the fisherman plugins I like:
  fisher add \
    daenney/rbenv \
    rafaelrinaldi/pure
end

function __append_to_path
  if test -d $argv[1]
    if not contains $argv[1] $fish_user_paths
      set -U fish_user_paths $argv[1] $fish_user_paths
    end
  end
end

# Pyenv
set -U PYENV_ROOT /usr/local/opt/pyenv
export PYENV_ROOT=/usr/local/opt/pyenv # Required to get pyenv to pick this up...
status --is-interactive; and source (pyenv init -|psub)
status --is-interactive; and source (pyenv virtualenv-init -|psub)

# ENV VARS
set -U EDITOR vim
set -U GREP_OPTIONS --color=auto

# Persistent PATH settings
__append_to_path ~/bin
__append_to_path ~/google-cloud-sdk/bin

# ABBREVIATIONS
abbr vi vim
abbr v vim
abbr g git

# ALIASES
# Note: Lazy loaded functions are better for shell startup times.

# STRIPE
if test -d ~/stripe
  __append_to_path ~/stripe/password-vault/bin
  __append_to_path ~/stripe/space-commander/bin
  __append_to_path ~/stripe/henson/bin
  . ~/stripe/space-commander/bin/sc-env-activate.fish
end
