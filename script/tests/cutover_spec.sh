#!/usr/bin/env bash
# Tests for script/cutover. Runs entirely in temp dirs - never touches $HOME.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
CUTOVER="$HERE/cutover"
PASS=0; FAIL=0
check() { if [ "$2" = "$3" ]; then echo "  ok: $1"; PASS=$((PASS+1));
          else echo "  FAIL: $1 (got '$2', want '$3')"; FAIL=$((FAIL+1)); fi; }

setup() {
  W="$(mktemp -d)"; REPO="$W/repo"; HOMEDIR="$W/home"
  mkdir -p "$REPO/tmux" "$HOMEDIR/.config"
  printf 'home' > "$REPO/.chezmoiroot"
  echo 'tracked' > "$REPO/tmux/tmux.conf"
  mkdir -p "$REPO/tmux/plugins/tpm"; echo 'untracked' > "$REPO/tmux/plugins/tpm/tpm"
  ln -s "$REPO/tmux" "$HOMEDIR/.config/tmux"
}
teardown() { rm -rf "$W"; }

echo "TEST: refuses when target is not a symlink"
setup; rm "$HOMEDIR/.config/tmux"; mkdir "$HOMEDIR/.config/tmux"
set +e; CUTOVER_SKIP_APPLY=1 DOTFILES_ROOT="$REPO" "$CUTOVER" tmux "$HOMEDIR/.config/tmux" >/dev/null 2>&1; rc=$?; set -e
check "non-symlink target refused" "$rc" "1"; teardown

echo "TEST: refuses when symlink does not point into the repo"
setup; rm "$HOMEDIR/.config/tmux"; ln -s /tmp "$HOMEDIR/.config/tmux"
set +e; CUTOVER_SKIP_APPLY=1 DOTFILES_ROOT="$REPO" "$CUTOVER" tmux "$HOMEDIR/.config/tmux" >/dev/null 2>&1; rc=$?; set -e
check "foreign symlink refused" "$rc" "1"; teardown

echo "TEST: dry run changes nothing"
setup
CUTOVER_DRY_RUN=1 CUTOVER_SKIP_APPLY=1 DOTFILES_ROOT="$REPO" "$CUTOVER" tmux "$HOMEDIR/.config/tmux" >/dev/null
check "dry run leaves symlink"  "$([ -L "$HOMEDIR/.config/tmux" ] && echo yes || echo no)" "yes"
check "dry run leaves repo dir" "$([ -d "$REPO/tmux" ] && echo yes || echo no)" "yes"
teardown

echo "TEST: cutover preserves tracked AND untracked state at the target"
setup
CUTOVER_SKIP_APPLY=1 DOTFILES_ROOT="$REPO" "$CUTOVER" tmux "$HOMEDIR/.config/tmux" >/dev/null
check "target is a real dir"     "$([ -d "$HOMEDIR/.config/tmux" ] && [ ! -L "$HOMEDIR/.config/tmux" ] && echo yes || echo no)" "yes"
check "tracked file survived"    "$(cat "$HOMEDIR/.config/tmux/tmux.conf" 2>/dev/null)" "tracked"
check "untracked state survived" "$(cat "$HOMEDIR/.config/tmux/plugins/tpm/tpm" 2>/dev/null)" "untracked"
check "repo dir is gone"         "$([ -e "$REPO/tmux" ] && echo yes || echo no)" "no"
teardown

echo "TEST: refuses to run twice (idempotence guard)"
setup
CUTOVER_SKIP_APPLY=1 DOTFILES_ROOT="$REPO" "$CUTOVER" tmux "$HOMEDIR/.config/tmux" >/dev/null
set +e; CUTOVER_SKIP_APPLY=1 DOTFILES_ROOT="$REPO" "$CUTOVER" tmux "$HOMEDIR/.config/tmux" >/dev/null 2>&1; rc=$?; set -e
check "second run refused" "$rc" "1"; teardown

echo "TEST: handles a nested subdir (git/gh)"
W="$(mktemp -d)"; REPO="$W/repo"; HOMEDIR="$W/home"
mkdir -p "$REPO/git/gh" "$HOMEDIR/.config"
echo 'hosts' > "$REPO/git/gh/hosts.yml"
ln -s "$REPO/git/gh" "$HOMEDIR/.config/gh"
CUTOVER_SKIP_APPLY=1 DOTFILES_ROOT="$REPO" "$CUTOVER" git/gh "$HOMEDIR/.config/gh" >/dev/null
check "nested subdir cut over" "$(cat "$HOMEDIR/.config/gh/hosts.yml" 2>/dev/null)" "hosts"
rm -rf "$W"

# The property that actually matters for ~/.claude: the chezmoi apply that runs
# AFTER the move must not disturb untracked runtime state (sessions, creds), and
# create_ must not clobber an existing settings file. This test exercises the
# real apply against a scratch source/destination.
echo "TEST: apply after cutover preserves untracked state and does not clobber create_"
if command -v chezmoi >/dev/null 2>&1; then
  W="$(mktemp -d)"; REPO="$W/repo"; HOMEDIR="$W/home"; LIVE="$W/live"; ST="$W/state"
  mkdir -p "$REPO/home/dot_claude/skills/foo" "$HOMEDIR" "$ST" \
           "$LIVE/skills/foo" "$LIVE/projects/sess1"
  printf 'home' > "$REPO/.chezmoiroot"
  echo 'global memory'       > "$REPO/home/dot_claude/CLAUDE.md"
  echo 'skill'               > "$REPO/home/dot_claude/skills/foo/SKILL.md"
  echo '{"seed":"skeleton"}' > "$REPO/home/dot_claude/create_private_settings.json"

  echo 'global memory'                > "$LIVE/CLAUDE.md"
  echo 'skill'                        > "$LIVE/skills/foo/SKILL.md"
  echo 'OAUTH-SECRET'                 > "$LIVE/.credentials.json"
  echo '{"real":"settings"}'          > "$LIVE/settings.json"
  echo 'transcript'                   > "$LIVE/projects/sess1/conversation.jsonl"
  ln -s "$LIVE" "$HOMEDIR/.claude"

  # stage the source where cutover expects it, then cut over WITH the real apply
  mkdir -p "$REPO/claude"; cp -r "$LIVE/." "$REPO/claude/"; rm -rf "$LIVE"
  ln -sfn "$REPO/claude" "$HOMEDIR/.claude"
  DOTFILES_ROOT="$REPO" \
  CUTOVER_CZ_ARGS="--source $REPO --destination $HOMEDIR --persistent-state $ST/s.boltdb" \
    "$CUTOVER" claude "$HOMEDIR/.claude" >/dev/null

  check "credentials survived apply"  "$(cat "$HOMEDIR/.claude/.credentials.json" 2>/dev/null)" "OAUTH-SECRET"
  check "session transcript survived" "$(cat "$HOMEDIR/.claude/projects/sess1/conversation.jsonl" 2>/dev/null)" "transcript"
  check "create_ did not clobber settings" "$(cat "$HOMEDIR/.claude/settings.json" 2>/dev/null)" '{"real":"settings"}'
  rm -rf "$W"
else
  echo "  SKIP: chezmoi not installed"
fi

echo; echo "passed=$PASS failed=$FAIL"; [ "$FAIL" -eq 0 ]
