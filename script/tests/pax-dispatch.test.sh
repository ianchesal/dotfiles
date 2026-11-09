#!/usr/bin/env bash
#
# Tests for home/dot_config/tmux/workmux/executable_pax-dispatch.sh. Builds a
# real git repo with a real worktree in a scratch dir, so prompt discovery is
# exercised against actual git plumbing, and fakes only workmux and tmux.
#
# Run: script/tests/pax-dispatch.test.sh

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
subject=$here/../../home/dot_config/tmux/workmux/executable_pax-dispatch.sh

# Resolve symlinks: macOS's $TMPDIR sits under /var -> /private/var, and the
# script reports paths from `git rev-parse --show-toplevel`, which resolves them.
work=$(cd "$(mktemp -d)" && pwd -P)
trap 'rm -rf "$work"' EXIT

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

# The instruction is multi-line; flatten each call onto one line so `grep -c`
# counts calls rather than matching lines.
cat >"$work/workmux" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" | tr '\n' ' ' >>"$WORKMUX_CALLS"
echo >>"$WORKMUX_CALLS"
exit 0
FAKE
chmod +x "$work/workmux"

cat >"$work/tmux" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >>"$TMUX_CALLS"
exit 0
FAKE
chmod +x "$work/tmux"

# A repo named "demo" on main, with a planning worktree that adds one prompt.
repo=$work/demo
git init -q -b main "$repo"
git -C "$repo" config user.email t@example.com
git -C "$repo" config user.name Test
mkdir -p "$repo/docs/superpowers/prompts"
echo base >"$repo/README.md"
git -C "$repo" add -A
git -C "$repo" commit -q -m base

wt=$work/demo__worktrees/planning
git -C "$repo" worktree add -q -b planning "$wt" >/dev/null 2>&1
mkdir -p "$wt/docs/superpowers/prompts"
echo 'do the thing' >"$wt/docs/superpowers/prompts/2026-09-21-thing-prompt.md"
git -C "$wt" add -A
git -C "$wt" commit -q -m 'Add prompt'

run() {
  : >"$work/wm-calls"
  : >"$work/tmux-calls"
  ( cd "${1:-$wt}" && WORKMUX_CALLS=$work/wm-calls TMUX_CALLS=$work/tmux-calls \
      WORKMUX_BIN=$work/workmux TMUX_BIN=$work/tmux "$subject" ) \
    >"$work/out" 2>"$work/err"
}

echo "pax-dispatch"

# --- the branch-added prompt is discovered -----------------------------------
run "$wt"
check "sends to the repo's main handle" "1" "$(grep -c '^send demo ' "$work/wm-calls" || true)"
check "names the prompt by absolute path" "1" \
  "$(grep -c "@$wt/docs/superpowers/prompts/2026-09-21-thing-prompt.md" "$work/wm-calls" || true)"
check "does not use a worktree-relative prompt path" "0" \
  "$(grep -c '@docs/superpowers' "$work/wm-calls" || true)"
check "names the worktree as workingDir" "1" "$(grep -c "workingDir=\"$wt\"" "$work/wm-calls" || true)"
check "names the branch" "1" "$(grep -c 'branch planning' "$work/wm-calls" || true)"
check "says the planning docs are committed" "1" "$(grep -c 'already committed' "$work/wm-calls" || true)"
check "switches to the pax window" "1" "$(grep -c 'select-window -t :pax' "$work/tmux-calls" || true)"

# --- dispatching from a subdirectory of the worktree still finds the prompt --
mkdir -p "$wt/docs"
run "$wt/docs" || true
check "subdirectory dispatch finds the prompt" "1" \
  "$(grep -c "@$wt/docs/superpowers/prompts/2026-09-21-thing-prompt.md" "$work/wm-calls" || true)"

# --- a worktree that added no prompt is an error -----------------------------
wt2=$work/demo__worktrees/empty
git -C "$repo" worktree add -q -b empty "$wt2" >/dev/null 2>&1
if run "$wt2"; then
  check "no prompt file fails" "nonzero exit" "exit 0"
else
  check "no prompt file fails" "nonzero exit" "nonzero exit"
fi
check "no prompt file sends nothing" "0" "$(wc -l <"$work/wm-calls" | tr -d ' ')"

# --- two prompts is ambiguous and must not guess -----------------------------
wt3=$work/demo__worktrees/two
git -C "$repo" worktree add -q -b two "$wt3" >/dev/null 2>&1
mkdir -p "$wt3/docs/superpowers/prompts"
echo a >"$wt3/docs/superpowers/prompts/2026-09-21-a-prompt.md"
echo b >"$wt3/docs/superpowers/prompts/2026-09-21-b-prompt.md"
git -C "$wt3" add -A
git -C "$wt3" commit -q -m 'Add two prompts'
if run "$wt3"; then
  check "ambiguous prompts fail" "nonzero exit" "exit 0"
else
  check "ambiguous prompts fail" "nonzero exit" "nonzero exit"
fi
check "ambiguous prompts name both" "1" "$(grep -c 'a-prompt.md' "$work/err" || true)"

# --- a gitignored prompt dir dispatches the prompt from disk -----------------
# A repo may keep planning docs out of git on purpose, so the prompt can only
# ever be on disk. A stray .DS_Store (globally ignored on macOS) beside it must
# not count as a second prompt.
wt4=$work/demo__worktrees/ignored
git -C "$repo" worktree add -q -b ignored "$wt4" >/dev/null 2>&1
echo 'docs/superpowers/' >"$wt4/.gitignore"
git -C "$wt4" add .gitignore
git -C "$wt4" commit -q -m 'Ignore superpowers docs'
mkdir -p "$wt4/docs/superpowers/prompts"
echo x >"$wt4/docs/superpowers/prompts/2026-09-21-x-prompt.md"
echo junk >"$wt4/docs/superpowers/prompts/.DS_Store"
if run "$wt4"; then
  check "gitignored prompt dispatches" "exit 0" "exit 0"
else
  check "gitignored prompt dispatches" "exit 0" "nonzero exit: $(cat "$work/err")"
fi
check "gitignored prompt named by absolute path" "1" \
  "$(grep -c "@$wt4/docs/superpowers/prompts/2026-09-21-x-prompt.md" "$work/wm-calls" || true)"
check "gitignored prompt is not claimed as committed" "0" "$(grep -c 'already committed' "$work/wm-calls" || true)"
check "gitignored prompt warns against force-adding" "1" "$(grep -c 'never force-add' "$work/wm-calls" || true)"

# --- a gitignored prompt dir with no prompt on disk is still an error --------
wt5=$work/demo__worktrees/ignored-empty
git -C "$repo" worktree add -q -b ignored-empty "$wt5" >/dev/null 2>&1
echo 'docs/superpowers/' >"$wt5/.gitignore"
git -C "$wt5" add .gitignore
git -C "$wt5" commit -q -m 'Ignore superpowers docs'
if run "$wt5"; then
  check "gitignored dir without prompt fails" "nonzero exit" "exit 0"
else
  check "gitignored dir without prompt fails" "nonzero exit" "nonzero exit"
fi
check "gitignored dir without prompt sends nothing" "0" "$(wc -l <"$work/wm-calls" | tr -d ' ')"

# --- a committable prompt that was never committed says to commit it ---------
wt6=$work/demo__worktrees/uncommitted
git -C "$repo" worktree add -q -b uncommitted "$wt6" >/dev/null 2>&1
mkdir -p "$wt6/docs/superpowers/prompts"
echo y >"$wt6/docs/superpowers/prompts/2026-09-21-y-prompt.md"
if run "$wt6"; then
  check "uncommitted prompt fails" "nonzero exit" "exit 0"
else
  check "uncommitted prompt fails" "nonzero exit" "nonzero exit"
fi
check "uncommitted prompt says to commit it" "1" "$(grep -c 'commit it' "$work/err" || true)"

# --- running from the main checkout is refused -------------------------------
if run "$repo"; then
  check "dispatch from main checkout fails" "nonzero exit" "exit 0"
else
  check "dispatch from main checkout fails" "nonzero exit" "nonzero exit"
fi

if [ "$failures" -gt 0 ]; then
  printf '  %d failure(s)\n' "$failures"
  exit 1
fi
