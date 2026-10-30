#!/usr/bin/env bash
#
# Tests for home/dot_config/herdr/executable_open-worktree.sh. Drives the
# script against a fake herdr and a fake fzf inside a scratch git repo, so no
# real workspace or claude is created.
#
# Run: script/tests/herdr-open-worktree.test.sh

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
subject=$here/../../home/dot_config/herdr/executable_open-worktree.sh

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
wts=${repo}__worktrees
git init -q -b main "$repo"
git -C "$repo" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
git -C "$repo" worktree add -q "$wts/old" -b old

# What `herdr worktree list` reports: the main checkout, an open worktree, a
# closed one, a detached one and a prunable one whose directory is gone.
all_worktrees="[
  {\"branch\":\"main\",\"path\":\"$repo\",\"is_linked_worktree\":false,\"is_detached\":false,\"is_prunable\":false,\"open_workspace_id\":\"w2\"},
  {\"branch\":\"feat/x\",\"path\":\"$wts/feat-x\",\"is_linked_worktree\":true,\"is_detached\":false,\"is_prunable\":false,\"open_workspace_id\":\"w3\"},
  {\"branch\":\"closed\",\"path\":\"$wts/closed\",\"is_linked_worktree\":true,\"is_detached\":false,\"is_prunable\":false,\"open_workspace_id\":null},
  {\"branch\":null,\"path\":\"$wts/det\",\"is_linked_worktree\":true,\"is_detached\":true,\"is_prunable\":false,\"open_workspace_id\":null},
  {\"branch\":\"gone\",\"path\":\"$wts/gone\",\"is_linked_worktree\":true,\"is_detached\":false,\"is_prunable\":true,\"open_workspace_id\":null}
]"

# A fake herdr that records its argv one call per line. `worktree list`
# answers with $WORKTREES; `worktree open` answers with pane w4:p1 and
# already_open=$ALREADY_OPEN, or fails when WORKTREE_FAIL is set; `agent start`
# fails with the code in AGENT_ERROR, if set.
mkdir -p "$work/bin"
cat >"$work/bin/herdr" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >>"$HERDR_CALLS"
case "$1 $2" in
  'worktree list')
    printf '{"result":{"worktrees":%s}}\n' "$WORKTREES"
    ;;
  'worktree open')
    if [ -n "${WORKTREE_FAIL:-}" ]; then
      echo '{"error":{"code":"git_failed","message":"worktree path does not exist"}}' >&2
      exit 1
    fi
    printf '{"result":{"already_open":%s,"root_pane":{"pane_id":"w4:p1"}}}\n' "${ALREADY_OPEN:-false}"
    ;;
  'agent start')
    if [ -n "${AGENT_ERROR:-}" ]; then
      printf '{"error":{"code":"%s","message":"nope"}}\n' "$AGENT_ERROR" >&2
      exit 1
    fi
    ;;
esac
FAKE
chmod +x "$work/bin/herdr"

# A fake fzf that saves the candidate lines and prints the first one containing
# $FZF_PICK, as real fzf prints the whole line whatever --with-nth shows.
cat >"$work/bin/fzf" <<'FAKE'
#!/usr/bin/env bash
cat >"$FZF_INPUT"
[ -n "${FZF_PICK:-}" ] || exit 130
grep -m 1 -F -- "$FZF_PICK" "$FZF_INPUT"
FAKE
chmod +x "$work/bin/fzf"

run() {
  local dir=$1 pick=$2
  : >"$work/calls"
  rm -f "$work/fzf-input"
  (cd "$dir" && PATH=$work/bin:$PATH HERDR_CALLS=$work/calls HERDR_BIN=$work/bin/herdr \
    FZF_INPUT=$work/fzf-input FZF_PICK=$pick WORKTREES=${WORKTREES:-$all_worktrees} \
    "$subject" </dev/null >"$work/out" 2>"$work/err")
}

echo "herdr-open-worktree"

# --- the picker lists this repo's linked worktrees, open ones marked ----------
run "$repo" closed
check "lists worktrees from the main checkout" "1" "$(grep -c -- "^worktree list --cwd $repo$" "$work/calls" || true)"
check "offers linked worktrees only, marking open ones" "feat/x (open)|closed|det (detached)" \
  "$(cut -f2 "$work/fzf-input" | paste -sd '|' -)"

# --- a closed worktree is opened and claude started in it ---------------------
check "opens the picked worktree" "1" \
  "$(grep -c -- "^worktree open --cwd $repo --path $wts/closed --focus$" "$work/calls" || true)"
check "starts claude in its root pane" "1" \
  "$(grep -c -- '^agent start closed --kind claude --pane w4:p1 -- --permission-mode auto$' "$work/calls" || true)"

# --- an open worktree is only focused ----------------------------------------
ALREADY_OPEN=true run "$repo" 'feat/x'
check "focuses an already open worktree" "1" \
  "$(grep -c -- "^worktree open --cwd $repo --path $wts/feat-x --focus$" "$work/calls" || true)"
check "starts no second claude in an open worktree" "0" "$(grep -c -- 'agent start' "$work/calls" || true)"

# --- agent names follow add-worktree.sh's rule --------------------------------
run "$repo" 'feat/x'
check "sanitizes the branch into an agent name" "1" "$(grep -c -- '^agent start feat-x ' "$work/calls" || true)"

run "$repo" '(detached)'
check "names a detached worktree's agent after its directory" "1" "$(grep -c -- '^agent start det ' "$work/calls" || true)"

# --- from inside a worktree, herdr still gets the main root -------------------
mkdir -p "$wts/old/sub"
run "$wts/old/sub" closed
check "a worktree subdirectory resolves to the main checkout" "1" \
  "$(grep -c -- "^worktree list --cwd $repo$" "$work/calls" || true)"

# --- a cancelled picker opens nothing ----------------------------------------
run "$repo" ''
check "cancelling fzf opens nothing" "0" "$(grep -c -- 'worktree open' "$work/calls" || true)"

# --- claude parked at its trust prompt is a success --------------------------
if AGENT_ERROR=agent_not_ready run "$repo" closed; then
  check "agent_not_ready is not a failure" "exit 0" "exit 0"
else
  check "agent_not_ready is not a failure" "exit 0" "nonzero exit"
fi

if AGENT_ERROR=agent_name_taken run "$repo" closed; then
  check "other agent errors fail" "nonzero exit" "exit 0"
else
  check "other agent errors fail" "nonzero exit" "nonzero exit"
fi

# --- a failed open shows herdr's message and starts nothing ------------------
if WORKTREE_FAIL=1 run "$repo" closed; then
  check "open failure fails" "nonzero exit" "exit 0"
else
  check "open failure fails" "nonzero exit" "nonzero exit"
fi
check "reports herdr's message" "1" "$(grep -c 'worktree path does not exist' "$work/err" || true)"
check "starts no agent after a failed open" "0" "$(grep -c -- 'agent start' "$work/calls" || true)"

# --- a repo with no worktrees says so and skips the picker -------------------
WORKTREES="[{\"branch\":\"main\",\"path\":\"$repo\",\"is_linked_worktree\":false,\"is_detached\":false,\"is_prunable\":false,\"open_workspace_id\":null}]" \
  run "$repo" main
check "no worktrees skips fzf" "no" "$([ -e "$work/fzf-input" ] && echo yes || echo no)"
check "no worktrees opens nothing" "0" "$(grep -c -- 'worktree open' "$work/calls" || true)"
check "no worktrees points at prefix+a" "1" "$(grep -c 'prefix+a' "$work/out" || true)"

# --- outside a repo is an error ----------------------------------------------
mkdir -p "$work/plain"
if run "$work/plain" closed; then
  check "outside a repo fails" "nonzero exit" "exit 0"
else
  check "outside a repo fails" "nonzero exit" "nonzero exit"
fi
check "outside a repo calls no herdr" "0" "$(wc -l <"$work/calls" | tr -d ' ')"

if [ "$failures" -gt 0 ]; then
  printf '  %d failure(s)\n' "$failures"
  exit 1
fi
