# Git aliases carried over from the zsh config so muscle memory works
# the same in a bash shell. Shell-level only: the second half of
# `gcom`, `gfu` and `grim` (`git com`, `git fixup`, `git main-branch`)
# are git-config aliases in ~/.config/git/config and already resolve
# here without any shell support.

alias gap='git add -p'
alias gau='git add -u'
alias gb='git branch'
alias gbD='git branch -D'
alias gbd='git branch -d'
alias gcoB='git checkout -B'
alias gcob='git checkout -b'
alias gci='git commit --verbose'
alias gcis='git commit --gpg-sign --verbose'
alias gclean='git clean --interactive -d'
alias gco='git checkout'
alias gcom='git com'
alias gcp='git cherry-pick'
alias gd='git diff --color=always'
alias gds='git diff --staged'
alias gf='git fetch'
alias gl='git log --color=always'
alias gll='git log --color=always | less -r'
alias glsut='git ls-files --others --exclude-standard'
alias gp='git pull'
alias gpd='git pull --dry-run'
alias gpfoh='git push --force-with-lease origin HEAD'
alias gpoh='git push origin HEAD'
alias gri='git rebase --interactive'
alias grim='git rebase --interactive --autosquash $(git main-branch)'
alias gs='git status --branch'
alias gsp='git stash push -u'
alias gss='git status --short --branch'
alias gsta='git stash --all'
alias gstc='git stash clear'
alias gstl='git stash list'
alias unfuck-mutagen='git clean -df'

# `git fixup` pipes 50 commits through fzf to pick the target, so the
# alias is only useful where fzf exists.
if command -v fzf >/dev/null 2>&1; then
  alias gfu='git fixup'
fi

# GitHub CLI wrappers. `ghd` is the same launcher the tmux prefix-h
# popup uses -- it picks the work or personal gh-dash config off the
# ~/.work_machine flag.
if command -v gh >/dev/null 2>&1; then
  alias ghd='${XDG_CONFIG_HOME:-$HOME/.config}/gh-dash/gh-dash.sh'
  alias ghpc='gh pr create --fill --assignee @me'
  alias ghpca='gh pr create --fill --label auto-assign-reviewers --assignee @me'
  alias ghpci='gh pr create --fill --assignee @me --reviewer persona-id/infrastructure'
  alias ghpcic='gh pr create --fill --assignee @me --label claude --reviewer persona-id/infrastructure'
  alias gst='gh stack'
fi

# Teach the aliases to complete like the commands they wrap -- without
# this, `gco <TAB>` offers filenames instead of branches, which is the
# tell that you're not in zsh. bash-completion v2 lazy-loads git's
# completion on first use of `git`, so __git_complete usually is not
# defined yet at shell start; source git's completion directly if we
# can find it, then wire the aliases up.
if ! declare -F __git_complete >/dev/null 2>&1; then
  for git_completion in \
    /usr/share/bash-completion/completions/git \
    /etc/bash_completion.d/git \
    "$(command -v brew >/dev/null 2>&1 && echo "$(brew --prefix)/etc/bash_completion.d/git-completion.bash")"; do
    if [[ -n "$git_completion" && -f "$git_completion" ]]; then
      # shellcheck disable=SC1090
      source "$git_completion"
      break
    fi
  done
  unset git_completion
fi

if declare -F __git_complete >/dev/null 2>&1; then
  __git_complete gb _git_branch
  __git_complete gbD _git_branch
  __git_complete gbd _git_branch
  __git_complete gco _git_checkout
  __git_complete gcoB _git_checkout
  __git_complete gcob _git_checkout
  __git_complete gcp _git_cherry_pick
  __git_complete gd _git_diff
  __git_complete gds _git_diff
  __git_complete gf _git_fetch
  __git_complete gl _git_log
  __git_complete gll _git_log
  __git_complete gp _git_pull
  __git_complete gri _git_rebase
fi
