#!/usr/bin/env bash
#
# Tests for home/dot_config/tmux/workmux/executable_pax-lead.sh. Drives the
# script against a fake tmux so no real session is created.
#
# Run: script/tests/pax-lead.test.sh

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
subject=$here/../../home/dot_config/tmux/workmux/executable_pax-lead.sh

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

# A fake tmux that records its argv one call per line. FAKE_HAS_PAX decides
# whether the pax session already exists.
cat >"$work/tmux" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >>"$TMUX_CALLS"
case "${1:-}" in
  has-session) [ -n "${FAKE_HAS_PAX:-}" ] || exit 1 ;;
esac
exit 0
FAKE
chmod +x "$work/tmux"

src=$work/src
mkdir -p "$src"

run() {
  : >"$work/calls"
  TMUX_CALLS=$work/calls SRC_ROOT=$src TMUX_BIN=$work/tmux PAX_BIN=paxfake \
    "$subject" >"$work/out" 2>"$work/err"
}

echo "pax-lead"

# --- no lead yet: one is started in ~/src under a stable session id ----------
run
check "probes for the pax session exactly" "1" "$(grep -c -- '^has-session -t =pax$' "$work/calls" || true)"
check "creates a detached pax session rooted at ~/src" "1" \
  "$(grep -c -- "^new-session -d -s pax -n pax -c $src " "$work/calls" || true)"
check "launches pi with the machine-wide session id" "1" \
  "$(grep -c -- 'paxfake --session-id pax$' "$work/calls" || true)"
check "pins the computer port" "1" "$(grep -c 'PAX_COMPUTER_PORT=8800 ' "$work/calls" || true)"
check "creates no split" "0" "$(grep -c -- 'split-window' "$work/calls" || true)"
check "switches to the lead" "1" "$(grep -c -- 'switch-client -t =pax' "$work/calls" || true)"

# --- a running lead is focused, never restarted ------------------------------
FAKE_HAS_PAX=1 run
check "does not recreate a running lead" "0" "$(grep -c -- 'new-session' "$work/calls" || true)"
check "switches to the running lead" "1" "$(grep -c -- 'switch-client -t =pax' "$work/calls" || true)"

if [ "$failures" -gt 0 ]; then
  printf '  %d failure(s)\n' "$failures"
  exit 1
fi
