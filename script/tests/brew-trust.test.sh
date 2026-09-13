#!/usr/bin/env bash
#
# Tests for script/brew-trust. Drives the script against a fake `brew` so the
# trust-list parsing is exercised without touching the real trust store.
#
# Run: script/tests/brew-trust.test.sh

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
subject=$here/../brew-trust

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

cat >"$work/brew" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
# Record just the trust calls: "<flag> <name>" per line.
if [ "${1:-}" = "trust" ]; then
  echo "$2 $3" >>"$FIXTURES/trusted-calls"
  exit 0
fi
echo "unexpected: $*" >&2
exit 1
FAKE
chmod +x "$work/brew"

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

run_trust() {
  rm -f "$work/trusted-calls"
  FIXTURES=$work BREW_BIN=$work/brew TRUSTED_FILE=$work/trusted "$subject" >"$work/out" 2>"$work/err"
}

calls() {
  [ -f "$work/trusted-calls" ] || return 0
  tr '\n' ' ' <"$work/trusted-calls" | sed 's/ $//'
}

echo "brew-trust"

# --- kinds map onto the right flags, in file order --------------------------
cat >"$work/trusted" <<'LIST'
formula raine/workmux/workmux
tap nikitabobko/tap
cask some/tap/thing
LIST
run_trust
check "maps kind onto the --flag" \
  "--formula raine/workmux/workmux --tap nikitabobko/tap --cask some/tap/thing" "$(calls)"

# --- comments and blank lines are skipped ------------------------------------
cat >"$work/trusted" <<'LIST'
# a comment

formula only/one/here
# trailing comment
LIST
run_trust
check "skips comments and blanks" "--formula only/one/here" "$(calls)"

# --- an unknown kind is a hard failure, not a silent skip --------------------
cat >"$work/trusted" <<'LIST'
formula good/one/here
nonsense bad/entry
LIST
if run_trust; then
  check "unknown kind fails" "nonzero exit" "exit 0"
else
  check "unknown kind fails" "nonzero exit" "nonzero exit"
fi
check "unknown kind names the offender" "yes" \
  "$(grep -q "unknown kind 'nonsense'" "$work/err" && echo yes || echo no)"

# --- a kind with no name is a hard failure -----------------------------------
printf 'formula\n' >"$work/trusted"
if run_trust; then
  check "missing name fails" "nonzero exit" "exit 0"
else
  check "missing name fails" "nonzero exit" "nonzero exit"
fi

# --- a missing trust list is a hard failure ----------------------------------
rm -f "$work/trusted"
if run_trust; then
  check "missing list fails" "nonzero exit" "exit 0"
else
  check "missing list fails" "nonzero exit" "nonzero exit"
fi

# --- no brew at all is a soft skip, not a failure ----------------------------
# The bootstrap runs this on machines where brew may be absent; exiting non-zero
# there would abort `chezmoi apply` over something recoverable.
printf 'formula a/b/c\n' >"$work/trusted"
if FIXTURES=$work BREW_BIN=$work/definitely-not-brew TRUSTED_FILE=$work/trusted \
  "$subject" >/dev/null 2>&1; then
  check "absent brew skips cleanly" "exit 0" "exit 0"
else
  check "absent brew skips cleanly" "exit 0" "nonzero exit"
fi

if [ "$failures" -gt 0 ]; then
  printf '  %d failure(s)\n' "$failures"
  exit 1
fi
