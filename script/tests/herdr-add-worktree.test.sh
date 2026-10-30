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
esac
FAKE
chmod +x "$work/herdr"

run() {
  local dir=$1 branch=$2
  : >"$work/calls"
  (cd "$dir" && HERDR_CALLS=$work/calls HERDR_BIN=$work/herdr BRANCH=$branch \
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
