# zoxide: a smarter cd
# See: https://github.com/ajeetdsouza/zoxide
if type zoxide >/dev/null; then
  eval "$(zoxide init --cmd cd zsh)"
fi
