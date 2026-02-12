#
# History hook to filter invalid commands
#
# This hook prevents mistyped commands from being added to zsh history.
# When you type `tmus ls` instead of `tmux ls`, the invalid command won't
# pollute your history or autocomplete suggestions.
#

zshaddhistory() {
  emulate -L zsh
  setopt extended_glob
  local -a cmd
  cmd=(${(z)1})  # Parse command line into array

  # Skip empty commands
  [[ -n "${cmd[1]}" ]] || return 1

  # Check if the command exists (includes builtins, functions, aliases, and executables)
  whence "${cmd[1]}" >& /dev/null && return 0

  # Command doesn't exist, don't add to history
  return 1
}
