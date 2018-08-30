# My fish shell configuration
# I've found https://github.com/jorgebucaran/fish-shell-cookbook incredibly
# useful for guiding my setup here.

# BOOTSTRAP
# Bootstrap Fisherman if it's not present
# See: https://github.com/fisherman/fisherman
if not test -f ~/.config/fish/functions/fisher.fish
  echo "Missing Fisherman! Will install now..."
  curl -Lo ~/.config/fish/functions/fisher.fish --create-dirs https://git.io/fisher
  chmod 755 ~/.config/fish/functions/fisher.fish
  # Need to wipe out existing fisherman configuration if we do a fresh
  # installation like this. Otherwise there are problems.
  rm -rf ~/.config/fisherman
  # Now install all the fisherman plugins I llike:
  fisher \
    rbenv \
    rafaelrinaldi/pure \
    edc/bass
end

# ENV VARS
set -U EDITOR vim

# ABBREVIATIONS
abbr vi vim
abbr v vim
abbr g git

# ALIASES
# Note: Lazy loaded functions are better for shell startup times.

# GOOGLE CLOUD SDK SETUP
if test -d $HOME/google-cloud-sdk
  bass source $HOME/google-cloud-sdk/path.bash.inc
  bass source $HOME/google-cloud-sdk/completion.bash.inc
end

# STRIPE
if test -d $HOME/stripe
  if not contains $HOME/stripe/password-vault/bin $fish_user_paths
    set -U fish_user_paths $HOME/stripe/password-vault/bin $fish_user_paths
  end

  if not contains $HOME/stripe/space-commander/bin $fish_user_paths
    set -U fish_user_paths $HOME/stripe/space-commander/bin $fish_user_paths
  end

  if not contains $HOME/stripe/henson/bin $fish_user_paths
    set -U fish_user_paths $HOME/stripe/henson/bin $fish_user_paths
  end
end
