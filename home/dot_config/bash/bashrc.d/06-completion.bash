if [[ -f /etc/bash_completion ]]; then
  # Debian/Ubuntu package path.
  source /etc/bash_completion
elif command -v brew >/dev/null 2>&1; then
  brew_completion="$(brew --prefix)/etc/profile.d/bash_completion.sh"
  if [[ -f "$brew_completion" ]]; then
    # shellcheck disable=SC1090
    source "$brew_completion"
  fi
  unset brew_completion
fi
