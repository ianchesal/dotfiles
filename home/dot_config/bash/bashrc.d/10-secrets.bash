# Load secrets last, as the zsh config does, so they can override anything above.
# Only trust the file when nobody but its owner can read it (mode 600 or 400,
# following a symlink as `source` would); warn and skip it otherwise.
# find's exact-mode -perm behaves the same on BSD and GNU, unlike stat's flags.
if [[ -f "${HOME}/.secrets" ]]; then
  if [[ -n "$(find -L "${HOME}/.secrets" -prune \( -perm 600 -o -perm 400 \) 2>/dev/null)" ]]; then
    source "${HOME}/.secrets"
  else
    printf 'bashrc: not sourcing ~/.secrets: mode is %s, want 600 or 400 (chmod 600 ~/.secrets)\n' \
      "$(ls -lLd "${HOME}/.secrets" | cut -c2-10)" >&2
  fi
fi
