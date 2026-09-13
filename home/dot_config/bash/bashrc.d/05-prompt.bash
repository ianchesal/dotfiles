if command -v oh-my-posh >/dev/null 2>&1; then
  eval "$(oh-my-posh init bash --config "$HOME/.config/ohmyposh/ohmyposh.json")"
else
  # Self-contained fallback: no oh-my-posh available (embedded box,
  # root shell with a stripped PATH, no network to reinstall it).
  # Still shells out once to `git rev-parse --git-dir` to locate the
  # repo, but reads .git/HEAD directly for the branch name itself
  # rather than a second git subprocess call per prompt render.
  bash_parse_git_branch() {
    local git_dir head_line
    git_dir=$(git rev-parse --git-dir 2>/dev/null) || return
    head_line=$(<"$git_dir/HEAD")
    if [[ "$head_line" == ref:\ refs/heads/* ]]; then
      printf ' (%s)' "${head_line#ref: refs/heads/}"
    else
      printf ' (%.7s)' "$head_line"
    fi
  }

  bash_prompt_command() {
    local exit_status=$?
    local color_reset='\[\e[0m\]'
    local color_prompt='\[\e[1;32m\]'
    if (( exit_status != 0 )); then
      color_prompt='\[\e[1;31m\]'
    fi
    PS1="${color_prompt}\u@\h${color_reset}:\[\e[1;34m\]\w${color_reset}\[\e[33m\]$(bash_parse_git_branch)${color_reset}\$ "
  }
  PROMPT_COMMAND="bash_prompt_command${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
fi
