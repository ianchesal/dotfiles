#!/usr/bin/env bash
#
# Pick one of the repo's worktrees with fzf and open it as a herdr workspace --
# the herdr twin of tmux's prefix+w "open" (workmux open).
#
# Bound in config.toml as a popup, so it runs in the focused pane's directory.
# Works from the repo or any of its worktrees: the list comes from the main
# checkout, resolved through git's common dir. The main checkout itself is not
# offered; prefix+f opens that. A worktree that already has a workspace is
# focused. One that doesn't gets a new workspace with claude started in it, as
# add-worktree.sh does -- `herdr worktree open` reports which case it was.
# As there, claude-oracle runs instead of claude when the pane's shell has it.
#
# Seams for script/tests/herdr-open-worktree.test.sh:
#   HERDR_BIN -- herdr executable (default: $HERDR_BIN_PATH, else herdr on PATH)
#   SHELL     -- the shell asked whether claude-oracle exists

set -euo pipefail

# herdr injects its binary path, but a brew upgrade under a running server
# leaves it pointing at a deleted Cellar path -- fall back to PATH.
herdr=${HERDR_BIN:-${HERDR_BIN_PATH:-herdr}}
[ -x "$herdr" ] || herdr=herdr

pause() {
  if [ -t 0 ]; then
    echo
    echo "Press any key to close."
    read -r -n 1 -s
  fi
}

fail() {
  echo "open-worktree: $*" >&2
  pause
  exit 1
}

# herdr agent names must match [a-z][a-z0-9_-]{0,31}. Same rule as add-worktree.sh.
agent_name() {
  local name
  name=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9_-]+/-/g')
  case $name in
    [a-z]*) ;;
    *) name=wt-$name ;;
  esac
  printf '%s\n' "${name:0:32}"
}

# Whether the shell a new pane runs has claude-oracle. Same probe as
# add-worktree.sh: it is usually a function in a machine-local rc file, so only
# an interactive shell sees it.
has_claude_oracle() {
  "${SHELL:-sh}" -ic 'command -v claude-oracle' </dev/null >/dev/null 2>&1
}

# Wait for herdr to detect a claude in pane $3 and name it $2; $1 labels the
# program in errors. As in add-worktree.sh, also run after `agent start` times
# out, because herdr then drops the name while claude carries on starting.
name_detected_claude() {
  local what=$1 agent=$2 pane=$3 out deadline
  deadline=$((SECONDS + 30))
  until out=$("$herdr" agent get "$pane" 2>&1) && [ "$(jq -r '.result.agent.agent' <<<"$out")" = claude ]; do
    [ "$SECONDS" -lt "$deadline" ] || fail "worktree is open but $what did not start in pane $pane"
    sleep 0.5
  done
  out=$("$herdr" agent rename "$pane" "$agent" 2>&1) ||
    fail "$what started in pane $pane but could not be named $agent: $out"
}

# Type claude-oracle into pane $2 and name the claude it starts $1, as
# add-worktree.sh does: herdr's `agent start` only runs the kind's own executable.
start_claude_oracle() {
  local agent=$1 pane=$2 out
  if "$herdr" agent get "$agent" >/dev/null 2>&1; then
    fail "worktree is open but an agent named $agent is already running"
  fi
  out=$("$herdr" pane run "$pane" 'claude-oracle --permission-mode auto' 2>&1) ||
    fail "worktree is open but claude-oracle could not be run: $out"
  name_detected_claude claude-oracle "$agent" "$pane"
  out=$("$herdr" agent wait "$agent" --until idle --until 'done' --until blocked --until working --timeout 30000 2>&1) ||
    fail "claude-oracle started in pane $pane but never became ready: $out"
}

common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) ||
  fail "$PWD is not in a git repo"
root=$(dirname "$common")

list=$("$herdr" worktree list --cwd "$root" 2>&1) ||
  fail "$(jq -r '.error.message' <<<"$list" 2>/dev/null || echo "$list")"

# One line per linked worktree: its path, then what fzf shows. A prunable
# worktree's directory is gone, so there is nothing to open.
candidates=$(jq -r '.result.worktrees[]
  | select(.is_linked_worktree and (.is_prunable | not))
  | (.branch // ((.path | split("/") | last) + " (detached)")) as $name
  | [.path, $name + (if .open_workspace_id then " (open)" else "" end)]
  | @tsv' <<<"$list")
if [ -z "$candidates" ]; then
  echo "$(basename "$root") has no worktrees; prefix+a adds one."
  pause
  exit 0
fi

# FZF_DEFAULT_OPTS sets --tmux; if herdr itself runs inside tmux, fzf would
# try to open a tmux popup of its own. Render inline in herdr's popup instead.
opts=$(echo "${FZF_DEFAULT_OPTS:-}" | sed -E 's/--tmux(=[^ ]+)?( [a-z]+)?//')
pick=$(FZF_DEFAULT_OPTS="$opts" fzf --prompt 'worktree> ' --delimiter '\t' --with-nth 2 <<<"$candidates") || exit 0
path=${pick%%$'\t'*}
branch=$(jq -r --arg p "$path" '.result.worktrees[] | select(.path == $p) | .branch // empty' <<<"$list")

out=$("$herdr" worktree open --cwd "$root" --path "$path" --focus 2>&1) ||
  fail "$(jq -r '.error.message' <<<"$out" 2>/dev/null || echo "$out")"
if [ "$(jq -r '.result.already_open' <<<"$out")" = true ]; then
  exit 0
fi
pane=$(jq -r '.result.root_pane.pane_id' <<<"$out")
agent=$(agent_name "${branch:-$(basename "$path")}")

# claude stopping at its "trust this folder" prompt counts as started.
if has_claude_oracle; then
  echo 'Starting claude-oracle...'
  start_claude_oracle "$agent" "$pane"
else
  echo 'Starting claude...'
  out=$("$herdr" agent start "$agent" --kind claude --pane "$pane" -- --permission-mode auto 2>&1) || {
    case $(jq -r '.error.code // empty' <<<"$out" 2>/dev/null) in
      agent_not_ready) ;;
      timeout) name_detected_claude claude "$agent" "$pane" ;;
      *) fail "worktree is open but claude did not start: $out" ;;
    esac
  }
fi
