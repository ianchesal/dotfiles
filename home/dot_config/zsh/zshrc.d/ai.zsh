# AI Shit

## Anthropic
CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=true

# On a work machine (~/.work_machine), `claude` runs `claude-oracle` instead, so
# sessions go through the Oracle gateway without having to remember the name.
# claude-oracle is a function in the unmanaged ~/.zsh_local and itself calls
# `command claude`, so this cannot recurse. If it is missing on a work machine,
# refuse rather than silently fall back to the direct API. Everywhere else, and
# for `command claude`, this is the plain binary.
claude() {
  if [[ -f "${HOME}/.work_machine" ]]; then
    if (( ${+functions[claude-oracle]} || ${+commands[claude-oracle]} )); then
      claude-oracle "$@"
    else
      print -u2 'claude: work machine but no claude-oracle defined (check ~/.zsh_local); use `command claude` to bypass'
      return 1
    fi
  else
    command claude "$@"
  fi
}
