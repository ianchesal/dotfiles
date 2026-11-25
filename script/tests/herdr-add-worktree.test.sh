#!/usr/bin/env bash
#
# Tests for home/dot_config/herdr/executable_add-worktree.sh. Drives the script
# against a fake herdr inside a scratch git repo, so no real worktree, workspace
# or claude is created.
#
# Run: script/tests/herdr-add-worktree.test.sh

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
subject=$here/../../home/dot_config/herdr/executable_add-worktree.sh

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
# macOS mktemp hands back /var/..., which git reports as /private/var/...
work=$(cd "$work" && pwd -P)

failures=0
check() {
  local label=$1 expected=$2 actual=$3
  if [ "$expected" = "$actual" ]; then
    printf '  ok   %s\n' "$label"
  else
    printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' "$label" "$expected" "$actual"
    failures=$((failures + 1))
  fi
}

repo=$work/src/demo
git init -q -b main "$repo"
git -C "$repo" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
git -C "$repo" worktree add -q "$work/src/demo__worktrees/old" -b old

# A fake herdr that records its argv one call per line. `worktree create`
# answers with pane w3:p1, or fails when WORKTREE_FAIL is set; `agent start`
# fails with the code in AGENT_ERROR, if set.
#
# The claude-oracle path: `agent get` on the pane finds no agent for the first
# DETECT_AFTER calls (default 0), then a claude; `agent get` on any other
# target finds one only when NAME_TAKEN is set; `agent wait` reports
# WAIT_STATUS (default idle).
cat >"$work/herdr" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >>"$HERDR_CALLS"
case "$1 $2" in
  'worktree create')
    if [ -n "${WORKTREE_FAIL:-}" ]; then
      echo '{"error":{"code":"git_failed","message":"branch is already checked out"}}' >&2
      exit 1
    fi
    echo '{"result":{"root_pane":{"pane_id":"w3:p1"}}}'
    ;;
  'agent start')
    if [ -n "${AGENT_ERROR:-}" ]; then
      printf '{"error":{"code":"%s","message":"nope"}}\n' "$AGENT_ERROR" >&2
      exit 1
    fi
    ;;
  'agent get')
    if [ "$3" = w3:p1 ]; then
      polls=$(grep -c '^agent get w3:p1$' "$HERDR_CALLS")
      if [ "$polls" -gt "${DETECT_AFTER:-0}" ]; then
        echo '{"result":{"agent":{"agent":"claude","agent_status":"unknown","pane_id":"w3:p1"}}}'
        exit 0
      fi
    elif [ -n "${NAME_TAKEN:-}" ]; then
      echo '{"result":{"agent":{"agent":"claude","agent_status":"idle","pane_id":"w9:p9"}}}'
      exit 0
    fi
    echo '{"error":{"code":"agent_not_found","message":"not found"}}' >&2
    exit 1
    ;;
  'agent wait')
    printf '{"result":{"agent":{"agent":"claude","agent_status":"%s"}}}\n' "${WAIT_STATUS:-idle}"
    ;;
esac
FAKE
chmod +x "$work/herdr"

# Fake $SHELL for the claude-oracle probe: it "has" claude-oracle when
# HAS_ORACLE is set, and records how it was asked.
cat >"$work/shell" <<'FAKE'
#!/usr/bin/env bash
echo "$*" >>"$SHELL_CALLS"
[ -n "${HAS_ORACLE:-}" ]
FAKE
chmod +x "$work/shell"

run() {
  local dir=$1 branch=$2
  : >"$work/calls"
  : >"$work/shell-calls"
  (cd "$dir" && HERDR_CALLS=$work/calls HERDR_BIN=$work/herdr BRANCH=$branch \
    SHELL=$work/shell SHELL_CALLS=$work/shell-calls \
    "$subject" </dev/null >"$work/out" 2>"$work/err")
}

echo "herdr-add-worktree"

# --- from the repo root ------------------------------------------------------
run "$repo" feat-x
check "creates the worktree beside the repo" "1" \
  "$(grep -c -- "^worktree create --cwd $repo --branch feat-x --path ${repo}__worktrees/feat-x --focus$" "$work/calls" || true)"
check "starts claude in the new pane" "1" \
  "$(grep -c -- '^agent start feat-x --kind claude --pane w3:p1 -- --permission-mode auto$' "$work/calls" || true)"

# --- from a subdirectory and from a worktree, herdr still gets the main root --
mkdir -p "$repo/sub/dir"
run "$repo/sub/dir" feat-y
check "a subdirectory resolves to the repo root" "1" "$(grep -c -- "^worktree create --cwd $repo " "$work/calls" || true)"

run "$work/src/demo__worktrees/old" feat-z
check "a worktree resolves to the main checkout" "1" "$(grep -c -- "^worktree create --cwd $repo " "$work/calls" || true)"

# --- branch names are flattened for the path and sanitized for the agent ------
run "$repo" Ian/Fix_Thing.2
check "flattens / in the worktree path" "1" "$(grep -c -- "--path ${repo}__worktrees/Ian-Fix_Thing.2 " "$work/calls" || true)"
check "keeps / in the branch" "1" "$(grep -c -- '--branch Ian/Fix_Thing.2 ' "$work/calls" || true)"
check "lowercases and sanitizes the agent name" "1" "$(grep -c -- '^agent start ian-fix_thing-2 ' "$work/calls" || true)"

run "$repo" 123-numeric
check "prefixes an agent name that would not start with a letter" "1" "$(grep -c -- '^agent start wt-123-numeric ' "$work/calls" || true)"

run "$repo" this-branch-name-is-far-too-long-for-herdr
check "truncates the agent name to 32 chars" "1" "$(grep -c -- '^agent start this-branch-name-is-far-too-long ' "$work/calls" || true)"

# --- claude parked at its trust prompt is a success --------------------------
if AGENT_ERROR=agent_not_ready run "$repo" trusty; then
  check "agent_not_ready is not a failure" "exit 0" "exit 0"
else
  check "agent_not_ready is not a failure" "exit 0" "nonzero exit"
fi

# herdr drops the name when `agent start` times out, though claude keeps starting
if AGENT_ERROR=timeout DETECT_AFTER=1 run "$repo" slow-start; then
  check "an agent start timeout is not a failure" "exit 0" "exit 0"
else
  check "an agent start timeout is not a failure" "exit 0" "nonzero exit: $(cat "$work/err")"
fi
check "after a timeout, waits for herdr to detect claude" "2" "$(grep -c -- '^agent get w3:p1$' "$work/calls" || true)"
check "after a timeout, names the claude it detects" "1" "$(grep -c -- '^agent rename w3:p1 slow-start$' "$work/calls" || true)"

run "$repo" quick-start
check "a clean agent start renames nothing" "0" "$(grep -c -- '^agent rename ' "$work/calls" || true)"

if AGENT_ERROR=agent_name_taken run "$repo" taken; then
  check "other agent errors fail" "nonzero exit" "exit 0"
else
  check "other agent errors fail" "nonzero exit" "nonzero exit"
fi

# --- a failed worktree shows herdr's message and starts nothing ---------------
if WORKTREE_FAIL=1 run "$repo" broken; then
  check "worktree failure fails" "nonzero exit" "exit 0"
else
  check "worktree failure fails" "nonzero exit" "nonzero exit"
fi
check "reports herdr's message" "1" "$(grep -c 'branch is already checked out' "$work/err" || true)"
check "starts no agent after a failed worktree" "0" "$(grep -c -- 'agent start' "$work/calls" || true)"

# --- the base branch is recorded for /merge and /rebase -----------------------
check "records the main checkout's branch as herdr-base" "main" \
  "$(git -C "$repo" config --get branch.feat-x.herdr-base || true)"

git -C "$repo" config branch.kept.herdr-base release
run "$repo" kept
check "keeps an existing herdr-base" "release" "$(git -C "$repo" config --get branch.kept.herdr-base || true)"

# --- non-interactive dispatch inputs (the /worktree and coordinator skills) ---
: >"$work/calls"
(cd "$repo" && HERDR_CALLS=$work/calls HERDR_BIN=$work/herdr BRANCH=dispatched BASE=old NO_FOCUS=1 \
  SHELL=$work/shell SHELL_CALLS=$work/shell-calls \
  PROMPT_FILE=/tmp/task.md "$subject" </dev/null >"$work/out" 2>"$work/err")
check "BASE and NO_FOCUS reach herdr" "1" \
  "$(grep -c -- "^worktree create --cwd $repo --branch dispatched --base old --path ${repo}__worktrees/dispatched --no-focus$" "$work/calls" || true)"
check "BASE is recorded as herdr-base" "old" "$(git -C "$repo" config --get branch.dispatched.herdr-base || true)"
check "PROMPT_FILE becomes claude's first message" "1" \
  "$(grep -c -- '^agent start dispatched --kind claude --pane w3:p1 -- --permission-mode auto Read the task in /tmp/task.md and carry it out.$' "$work/calls" || true)"
check "reports the agent and pane" "agent dispatched in pane w3:p1" "$(tail -n 1 "$work/out")"

# --- claude-oracle, when the pane's shell has it, replaces claude --------------
run "$repo" plain
check "asks an interactive \$SHELL for claude-oracle" "-ic command -v claude-oracle" "$(cat "$work/shell-calls")"
check "without claude-oracle, nothing is typed into the pane" "0" "$(grep -c -- '^pane run ' "$work/calls" || true)"

HAS_ORACLE=1 run "$repo" oracle
check "types claude-oracle into the new pane" "1" \
  "$(grep -c -- '^pane run w3:p1 claude-oracle --permission-mode auto$' "$work/calls" || true)"
check "does not use agent start for claude-oracle" "0" "$(grep -c -- '^agent start ' "$work/calls" || true)"
check "checks the agent name is free before launching" "agent get oracle" "$(grep -m1 -- '^agent get ' "$work/calls" || true)"
check "names the detected claude after the branch" "1" "$(grep -c -- '^agent rename w3:p1 oracle$' "$work/calls" || true)"
check "waits for it to be ready" "1" \
  "$(grep -c -- '^agent wait oracle --until idle --until done --until blocked --until working --timeout 30000$' "$work/calls" || true)"
check "reports the agent and pane" "agent oracle in pane w3:p1" "$(tail -n 1 "$work/out")"

DETECT_AFTER=2 HAS_ORACLE=1 run "$repo" slow
check "polls until herdr detects claude" "3" "$(grep -c -- '^agent get w3:p1$' "$work/calls" || true)"
check "names it only after detection" "agent rename w3:p1 slow" \
  "$(grep -A1 -- '^agent get w3:p1$' "$work/calls" | tail -n 1)"

WAIT_STATUS=blocked HAS_ORACLE=1 run "$repo" trusty-oracle
check "reports claude-oracle parked at the trust prompt" "1" \
  "$(grep -c 'claude is waiting at a startup prompt (folder trust?) in pane w3:p1' "$work/out" || true)"

if NAME_TAKEN=1 HAS_ORACLE=1 run "$repo" clash; then
  check "a taken agent name fails" "nonzero exit" "exit 0"
else
  check "a taken agent name fails" "nonzero exit" "nonzero exit"
fi
check "launches nothing when the name is taken" "0" "$(grep -c -- '^pane run ' "$work/calls" || true)"

: >"$work/calls"
(cd "$repo" && HERDR_CALLS=$work/calls HERDR_BIN=$work/herdr BRANCH=oracle-task HAS_ORACLE=1 \
  SHELL=$work/shell SHELL_CALLS=$work/shell-calls \
  PROMPT_FILE=/tmp/task.md "$subject" </dev/null >"$work/out" 2>"$work/err")
check "PROMPT_FILE reaches claude-oracle as one shell word" "1" \
  "$(grep -cxF -- 'pane run w3:p1 claude-oracle --permission-mode auto Read\ the\ task\ in\ /tmp/task.md\ and\ carry\ it\ out.' "$work/calls" || true)"

# --- an empty branch is a quiet no-op ----------------------------------------
run "$repo" ''
check "an empty branch prompt calls no herdr" "0" "$(wc -l <"$work/calls" | tr -d ' ')"

# --- outside a repo is an error ----------------------------------------------
mkdir -p "$work/plain"
if run "$work/plain" feat; then
  check "outside a repo fails" "nonzero exit" "exit 0"
else
  check "outside a repo fails" "nonzero exit" "nonzero exit"
fi

if [ "$failures" -gt 0 ]; then
  printf '  %d failure(s)\n' "$failures"
  exit 1
fi
