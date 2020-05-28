# My fish shell configuration
# I've found https://github.com/jorgebucaran/fish-shell-cookbook incredibly
# useful for guiding my setup here.

function __append_to_path
  if test -d $argv[1]
    if not contains $argv[1] $fish_user_paths
      set -U fish_user_paths $argv[1] $fish_user_paths
    end
  end
end

function __read_confirm
  set confirm 'x'
  if [ -z "$argv" ]; # No arguments
    set message 'Do you want to continue? [y/N] '
  else
    set message "$argv "
  end
  while true
    read -l -P $message confirm
    switch $confirm
      case Y y
        return 0
      case '' N n
        return 1
    end
  end
end

# Bootstrap Fisherman if it's not present
# See: https://github.com/jorgebucaran/fisher
if not functions -q fisher
  if __read_confirm "fisher is not installed -- install fisher now? [y/N] "
    echo "Installing fisher..." >&2
    set -q XDG_CONFIG_HOME; or set XDG_CONFIG_HOME ~/.config
    curl https://git.io/fisher --create-dirs -sLo $XDG_CONFIG_HOME/fish/functions/fisher.fish
    # Now install all the fisherman plugins I like:
    echo "You need to run:"
    echo fisher add \
      daenney/rbenv \
      rafaelrinaldi/pure \
      oh-my-fish/plugin-aws \
      jethrokuan/fzf
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

# bat: https://github.com/sharkdp/bat#configuration-file
set -U BAT_CONFIG_PATH ~/src/dotfiles/bat/bat.conf

# Opt out of Homebrew analytics
set -U HOMEBREW_NO_ANALYTICS 1
# Cleanup on install
set -U HOMEBREW_INSTALL_CLEANUP 1
# Cask options
set -U HOMEBREW_CASK_OPTS --appdir=~/Applications

# Persistent PATH settings
__append_to_path ~/bin
__append_to_path ~/google-cloud-sdk/bin

# ABBREVIATIONS
abbr vi vim
abbr v vim
abbr g git

# ALIASES
# Note: Lazy loaded functions are better for shell startup times.
