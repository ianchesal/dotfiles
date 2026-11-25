#!/usr/bin/env bash
#
# Make a git worktree for a branch, open it as a herdr workspace and start
# claude in it -- the herdr twin of tmux's prefix+w "add" (workmux add).
#
# Bound in config.toml as a popup, so it runs in the focused pane's directory.
# Works from the repo or any of its worktrees: herdr only creates worktrees from
# the main checkout, so the root is resolved through git's common dir. A new
# branch is cut from the current HEAD; an existing one is checked out. The
# checkout lands in <repo>__worktrees/<branch>, the layout workmux uses, with
# any / in the branch flattened to -.
#
# claude stopping at its "trust this folder" prompt counts as started: every
# new worktree path asks once.
#
# A machine whose shell has a claude-oracle command (a wrapper that runs claude
# through a work gateway) gets that instead of plain claude. It is usually a
# function in a machine-local rc file, which only an interactive shell can see,
# so the new pane's kind of shell ($SHELL -i) is asked. herdr's `agent start`
# can only run the kind's own executable, so claude-oracle is typed into the
# pane instead, and the claude it starts is named once herdr detects it.
#
# The branch it was cut from is recorded as git config branch.<branch>.herdr-base
# (unless one is already set), which is where the /merge and /rebase Claude
# skills land it.
#
# Inputs, for the popup's tests and for the /worktree and coordinator Claude
# skills, which dispatch through this script non-interactively:
#   HERDR_BIN   -- herdr executable (default: $HERDR_BIN_PATH, else herdr on PATH)
#   BRANCH      -- skip the prompt and use this branch
#   BASE        -- ref to cut a new branch from (default: the main checkout's HEAD)
#   PROMPT_FILE -- claude's first message tells it to read this file and do the task
#   NO_FOCUS    -- 1 leaves focus where it is instead of jumping to the new workspace
#   SHELL       -- the shell asked whether claude-oracle exists (tests point it at a fake)

set -euo pipefail

# herdr injects its binary path, but a brew upgrade under a running server
# leaves it pointing at a deleted Cellar path -- fall back to PATH.
herdr=${HERDR_BIN:-${HERDR_BIN_PATH:-herdr}}
[ -x "$herdr" ] || herdr=herdr

fail() {
  echo "add-worktree: $*" >&2
  if [ -t 0 ]; then
    echo
    echo "Press any key to close."
    read -r -n 1 -s
  fi
  exit 1
}

# herdr agent names must match [a-z][a-z0-9_-]{0,31}.
agent_name() {
  local name
  name=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9_-]+/-/g')
  case $name in
    [a-z]*) ;;
    *) name=wt-$name ;;
  esac
  printf '%s\n' "${name:0:32}"
}

# Whether the shell a new pane runs has claude-oracle, as executable, function
# or alias. -i loads the rc files that define it; zsh's zle complaints about
# having no terminal go to /dev/null with everything else.
has_claude_oracle() {
  "${SHELL:-sh}" -ic 'command -v claude-oracle' </dev/null >/dev/null 2>&1
}

# Type claude-oracle into $pane, wait for herdr to detect the claude it runs,
# name it $agent, and wait until it is ready -- what `agent start` does for a
# plain claude. Prints the startup-prompt note when claude stops at one.
start_claude_oracle() {
  local cmd=claude-oracle arg out deadline status
  # Checked up front, as `agent start` does: a clash after launch would leave
  # an unnamed claude that the coordinator skill can't address.
  if "$herdr" agent get "$agent" >/dev/null 2>&1; then
    fail "worktree is open but an agent named $agent is already running"
  fi
  for arg in "${claude_args[@]}"; do cmd+=" $(printf '%q' "$arg")"; done
  out=$("$herdr" pane run "$pane" "$cmd" 2>&1) ||
    fail "worktree is open but claude-oracle could not be run: $out"

  deadline=$((SECONDS + 30))
  until out=$("$herdr" agent get "$pane" 2>&1) && [ "$(jq -r '.result.agent.agent' <<<"$out")" = claude ]; do
    [ "$SECONDS" -lt "$deadline" ] || fail "worktree is open but claude-oracle did not start in pane $pane"
    sleep 0.5
  done
  out=$("$herdr" agent rename "$pane" "$agent" 2>&1) ||
    fail "claude-oracle started in pane $pane but could not be named $agent: $out"

  out=$("$herdr" agent wait "$agent" --until idle --until 'done' --until blocked --until working --timeout 30000 2>&1) ||
    fail "claude-oracle started in pane $pane but never became ready: $out"
  status=$(jq -r '.result.agent.agent_status' <<<"$out")
  if [ "$status" = blocked ]; then
    echo "claude is waiting at a startup prompt (folder trust?) in pane $pane"
  fi
}

common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) ||
  fail "$PWD is not in a git repo"
root=$(dirname "$common")

branch=${BRANCH:-}
if [ -z "$branch" ]; then
  printf 'Branch: '
  read -r branch || true
fi
[ -n "$branch" ] || exit 0

base=${BASE:-}
focus=--focus
[ "${NO_FOCUS:-}" = 1 ] && focus=--no-focus

out=$("$herdr" worktree create --cwd "$root" --branch "$branch" ${base:+--base "$base"} \
  --path "${root}__worktrees/${branch//\//-}" "$focus" 2>&1) ||
  fail "$(jq -r '.error.message' <<<"$out" 2>/dev/null || echo "$out")"
pane=$(jq -r '.result.root_pane.pane_id' <<<"$out")

recorded=${base:-$(git -C "$root" branch --show-current 2>/dev/null || true)}
if [ -n "$recorded" ] && ! git -C "$root" config --get "branch.$branch.herdr-base" >/dev/null; then
  git -C "$root" config "branch.$branch.herdr-base" "$recorded" || true
fi

agent=$(agent_name "$branch")
claude_args=(--permission-mode auto)
[ -n "${PROMPT_FILE:-}" ] && claude_args+=("Read the task in $PROMPT_FILE and carry it out.")

if has_claude_oracle; then
  echo 'Starting claude-oracle...'
  start_claude_oracle
else
  echo 'Starting claude...'
  out=$("$herdr" agent start "$agent" --kind claude --pane "$pane" -- "${claude_args[@]}" 2>&1) || {
    [ "$(jq -r '.error.code // empty' <<<"$out" 2>/dev/null)" = agent_not_ready ] ||
      fail "worktree is open but claude did not start: $out"
    echo "claude is waiting at a startup prompt (folder trust?) in pane $pane"
  }
fi
echo "agent $agent in pane $pane"
