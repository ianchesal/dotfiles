#!/usr/bin/env bash
#
# Tests for the ~/.profile guard block bootstrap/bash-only.sh installs. Runs
# the whole script offline against a scratch $HOME, with REPO_RAW pointed at
# this checkout through a file:// URL, then drives the resulting ~/.profile
# through a bash invoked as `sh` to prove the re-exec happens only when it
# should.
#
# Run: script/tests/bash-only-profile.test.sh

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../.." && pwd)
subject=$repo/bootstrap/bash-only.sh

work=$(mktemp -d)
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

begin='# >>> parachute sh->bash >>>'
end='# <<< parachute sh->bash <<<'

install_into() {
  HOME=$1 REPO_RAW="file://$repo" bash "$subject" >/dev/null
}

count_blocks() { grep -cxF "$begin" "$1/.profile" || true; }
count_backups() { find "$1" -maxdepth 1 -name '.profile.bak.*' | wc -l | tr -d ' '; }

echo 'bash-only.sh: ~/.profile guard'

# --- no existing ~/.profile: one is created holding just the block
h=$work/fresh
mkdir -p "$h"
install_into "$h"
check 'fresh: file created' yes "$([ -f "$h/.profile" ] && echo yes || echo no)"
check 'fresh: starts with the block' "$begin" "$(head -n1 "$h/.profile")"
check 'fresh: ends with the block' "$end" "$(tail -n1 "$h/.profile")"
check 'fresh: no backup' 0 "$(count_backups "$h")"

# --- Debian-style skel ~/.profile: block prepended, original kept verbatim
h=$work/debian
mkdir -p "$h"
cat >"$h/.profile" <<'SKEL'
# ~/.profile: executed by the command interpreter for login shells.
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi
SKEL
cp "$h/.profile" "$work/debian-original"
install_into "$h"
check 'debian: block first' "$begin" "$(head -n1 "$h/.profile")"
check 'debian: original content kept after the block' \
  "$(cat "$work/debian-original")" "$(sed "1,/^${end}\$/d" "$h/.profile")"
check 'debian: one block' 1 "$(count_blocks "$h")"
check 'debian: backup made' 1 "$(count_backups "$h")"

# --- rerun: unchanged, no second block, no new backup
cp "$h/.profile" "$work/debian-after-first"
sleep 1 # backup suffix has 1s resolution; a new backup would get a new name
install_into "$h"
check 'rerun: file unchanged' "$(cat "$work/debian-after-first")" "$(cat "$h/.profile")"
check 'rerun: still one block' 1 "$(count_blocks "$h")"
check 'rerun: no new backup' 1 "$(count_backups "$h")"

# --- stale block (older guard text): replaced in place, rest kept
h=$work/stale
mkdir -p "$h"
printf '%s\n%s\n%s\n%s\n' "$begin" 'echo old guard' "$end" 'export KEEP=1' >"$h/.profile"
install_into "$h"
check 'stale: one block' 1 "$(count_blocks "$h")"
check 'stale: old guard text gone' 0 "$(grep -c 'echo old guard' "$h/.profile" || true)"
check 'stale: trailing content kept' 'export KEEP=1' "$(tail -n1 "$h/.profile")"

# --- behaviour: a HOME holding only the guard, driven through bash-as-sh
h=$work/behave
mkdir -p "$h" "$work/bin"
cp "$work/fresh/.profile" "$h/.profile"
bash_path=$(command -v bash)
ln -s "$bash_path" "$work/bin/sh"
probe='shopt -qo posix && echo posix=on || echo posix=off'
run() { printf '%s\n' "$probe" | env -i HOME="$h" PATH="$work/bin:/usr/bin:/bin" "$@" 2>/dev/null | tail -n1; }

check 'interactive sh login re-execs bash' posix=off "$(run "$work/bin/sh" -il)"
check 'non-interactive sh login left alone' posix=on "$(run "$work/bin/sh" -l)"
check 'real bash login untouched' posix=off "$(run "$bash_path" -il)"

if [ "$failures" -ne 0 ]; then
  printf '%d failure(s)\n' "$failures"
  exit 1
fi
