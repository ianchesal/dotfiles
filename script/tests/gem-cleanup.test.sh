#!/usr/bin/env bash
#
# Tests for script/gem-cleanup. Drives the script against a fake `gem` so the
# default-gem conflict parsing can be exercised without touching real gems.
#
# Run: script/tests/gem-cleanup.test.sh

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
subject=$here/../gem-cleanup

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# The script derives the repo root as <script dir>/.., and scans it for
# Gemfile.lock files -- so stage a fake repo with the script inside it.
mkdir -p "$work/repo/script"
cp "$subject" "$work/repo/script/gem-cleanup"

cat >"$work/gem" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
case "$1" in
  cleanup)   echo "fake gem cleanup" ;;
  list)      cat "$FIXTURES/gem-list" ;;
  uninstall) echo "$2 $4" >>"$FIXTURES/uninstalled" ;;
  *) echo "unexpected: $*" >&2; exit 1 ;;
esac
FAKE
chmod +x "$work/gem"

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

run_cleanup() {
  # HOME is redirected so the ~/.work_machine check is under test control.
  HOME=$work/home FIXTURES=$work GEM_BIN=$work/gem "$work/repo/script/gem-cleanup"
}

removed() {
  [ -f "$work/uninstalled" ] || return 0
  tr '\n' ' ' <"$work/uninstalled" | sed 's/ $//'
}

reset_fixtures() {
  rm -rf "${work:?}/home" "${work:?}/uninstalled"
  mkdir -p "$work/home"
  find "$work/repo" -name Gemfile.lock -delete
}

echo "gem-cleanup"

# --- only gems with both a default and an installed version are removed -----
reset_fixtures
cat >"$work/gem-list" <<'EOF'
json (default: 2.7.1, 2.6.3)
psych (default: 5.1.2)
rake (13.0.6)
stringio (default: 3.1.0, 3.0.9, 3.0.8)
EOF
run_cleanup >/dev/null
check "removes only installed-alongside-default versions" \
  "json 2.6.3 stringio 3.0.9 stringio 3.0.8" "$(removed)"

# --- versions pinned in a Gemfile.lock are protected ------------------------
reset_fixtures
cat >"$work/gem-list" <<'EOF'
json (default: 2.7.1, 2.6.3)
EOF
printf 'GEM\n  specs:\n    json (2.6.3)\n      other (>= 0)\n' >"$work/repo/Gemfile.lock"
output=$(run_cleanup)
check "pinned version is not removed" "" "$(removed)"
check "pinned version is reported as skipped" "1" \
  "$(grep -c 'pinned in Gemfile.lock' <<<"$output")"

# --- six-space dependency lines must not be read as pins --------------------
reset_fixtures
cat >"$work/gem-list" <<'EOF'
json (default: 2.7.1, 2.6.3)
EOF
printf 'GEM\n  specs:\n    somegem (1.0.0)\n      json (2.6.3)\n' >"$work/repo/Gemfile.lock"
run_cleanup >/dev/null
check "dependency lines do not protect a version" "json 2.6.3" "$(removed)"

# --- BUNDLED WITH protects the bundler version ------------------------------
reset_fixtures
cat >"$work/gem-list" <<'EOF'
bundler (default: 2.5.3, 2.4.22)
EOF
printf 'GEM\n  specs:\n\nBUNDLED WITH\n   2.4.22\n' >"$work/repo/Gemfile.lock"
run_cleanup >/dev/null
check "BUNDLED WITH version is protected" "" "$(removed)"

# --- a work machine short-circuits before touching anything -----------------
reset_fixtures
cat >"$work/gem-list" <<'EOF'
json (default: 2.7.1, 2.6.3)
EOF
touch "$work/home/.work_machine"
output=$(run_cleanup)
check "work machine removes nothing" "" "$(removed)"
check "work machine says why" "1" "$(grep -c 'Skipping gem cleanup on work machine' <<<"$output")"

if [ "$failures" -gt 0 ]; then
  printf '\n%d failure(s)\n' "$failures"
  exit 1
fi
printf '\nall passed\n'
