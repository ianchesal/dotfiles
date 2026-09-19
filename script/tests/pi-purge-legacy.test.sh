#!/usr/bin/env bash
#
# Tests for script/pi-purge-legacy. Builds fake asdf and npm-global trees in a
# scratch dir so the removal logic runs without touching a real install, and
# fakes pgrep so the "a pi is still running" refusal can be exercised.
#
# Run: script/tests/pi-purge-legacy.test.sh

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
subject=$here/../pi-purge-legacy

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Fake pgrep: prints whatever $FIXTURES/running holds, so a test can stage a
# live pi session. Absent file means nothing is running, and pgrep's own
# convention is to exit 1 when it matches nothing.
cat >"$work/pgrep" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
if [ -s "$FIXTURES/running" ]; then cat "$FIXTURES/running"; else exit 1; fi
FAKE
chmod +x "$work/pgrep"

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

pkg=@earendil-works/pi-coding-agent

# A machine in the pre-cleanup state: pi installed under two asdf node versions,
# a stray shim, the interim ~/.npm-global copy, and the canonical install.
build_tree() {
  rm -rf "$work/asdf" "$work/npm-global" "$work/pi-prefix" "$work/local-bin"
  rm -f "$work/running"
  local v
  for v in 24.10.0 26.7.0; do
    mkdir -p "$work/asdf/installs/nodejs/$v/lib/node_modules/$pkg/dist"
    echo bundle >"$work/asdf/installs/nodejs/$v/lib/node_modules/$pkg/dist/cli.js"
    mkdir -p "$work/asdf/installs/nodejs/$v/bin"
    echo shim >"$work/asdf/installs/nodejs/$v/bin/pi"
    # An unrelated package under the same node must survive.
    mkdir -p "$work/asdf/installs/nodejs/$v/lib/node_modules/typescript"
    echo tsc >"$work/asdf/installs/nodejs/$v/lib/node_modules/typescript/index.js"
  done
  mkdir -p "$work/asdf/shims"
  echo shim >"$work/asdf/shims/pi"
  echo shim >"$work/asdf/shims/node"

  mkdir -p "$work/npm-global/lib/node_modules/$pkg" "$work/npm-global/bin"
  echo bundle >"$work/npm-global/lib/node_modules/$pkg/cli.js"
  echo link >"$work/npm-global/bin/pi"

  # The canonical install and its wrapper: must come through untouched.
  mkdir -p "$work/pi-prefix/lib/node_modules/$pkg" "$work/local-bin"
  echo canonical >"$work/pi-prefix/lib/node_modules/$pkg/cli.js"
  echo wrapper >"$work/local-bin/pi"
}

run_purge() {
  FIXTURES=$work PGREP_BIN=$work/pgrep \
    ASDF_DIR=$work/asdf NPM_GLOBAL_PREFIX=$work/npm-global PI_PREFIX=$work/pi-prefix \
    "$subject" "$@"
}

exists() { [ -e "$1" ] && echo yes || echo no; }

echo "pi-purge-legacy"

# --- removes every legacy tree, across all node versions --------------------
build_tree
FORCE=1 run_purge >/dev/null
check "removes the asdf package tree (24.10.0)" \
  "no" "$(exists "$work/asdf/installs/nodejs/24.10.0/lib/node_modules/@earendil-works")"
check "removes the asdf package tree (26.7.0)" \
  "no" "$(exists "$work/asdf/installs/nodejs/26.7.0/lib/node_modules/@earendil-works")"
check "removes the asdf bin entries" \
  "no" "$(exists "$work/asdf/installs/nodejs/24.10.0/bin/pi")"
check "removes the asdf shim" "no" "$(exists "$work/asdf/shims/pi")"
check "removes the npm-global package tree" \
  "no" "$(exists "$work/npm-global/lib/node_modules/@earendil-works")"
check "removes the npm-global bin entry" "no" "$(exists "$work/npm-global/bin/pi")"

# --- and touches nothing else ------------------------------------------------
check "leaves the canonical install alone" \
  "yes" "$(exists "$work/pi-prefix/lib/node_modules/@earendil-works/pi-coding-agent/cli.js")"
check "leaves the wrapper alone" "yes" "$(exists "$work/local-bin/pi")"
check "leaves unrelated npm packages alone" \
  "yes" "$(exists "$work/asdf/installs/nodejs/24.10.0/lib/node_modules/typescript/index.js")"
check "leaves other shims alone" "yes" "$(exists "$work/asdf/shims/node")"

# --- refuses while a pi session is live -------------------------------------
build_tree
printf '4242\n' >"$work/running"
if run_purge </dev/null >"$work/out" 2>&1; then
  check "refuses when pi is running" "nonzero exit" "exit 0"
else
  check "refuses when pi is running" "nonzero exit" "nonzero exit"
fi
check "refusal deletes nothing" \
  "yes" "$(exists "$work/asdf/installs/nodejs/24.10.0/lib/node_modules/@earendil-works")"
check "refusal names the pid" "yes" "$(grep -q 4242 "$work/out" && echo yes || echo no)"

# --- FORCE overrides the running-session refusal ----------------------------
build_tree
printf '4242\n' >"$work/running"
FORCE=1 run_purge >/dev/null 2>&1
check "FORCE purges despite a live session" \
  "no" "$(exists "$work/asdf/installs/nodejs/24.10.0/lib/node_modules/@earendil-works")"

# --- preview reports without removing ---------------------------------------
build_tree
run_purge --preview >"$work/out" 2>&1
check "preview removes nothing" \
  "yes" "$(exists "$work/asdf/installs/nodejs/24.10.0/lib/node_modules/@earendil-works")"
check "preview lists the shim" "yes" "$(grep -q "$work/asdf/shims/pi" "$work/out" && echo yes || echo no)"

# --- a clean machine is a no-op ---------------------------------------------
build_tree
FORCE=1 run_purge >/dev/null
FORCE=1 run_purge >"$work/out" 2>&1
check "second run is a clean no-op" "exit 0" "exit 0"
check "second run says there is nothing to remove" \
  "yes" "$(grep -qi 'nothing to remove' "$work/out" && echo yes || echo no)"

# --- preview on a clean machine still exits 0 -------------------------------
if run_purge --preview >/dev/null 2>&1; then
  check "preview on a clean machine exits 0" "exit 0" "exit 0"
else
  check "preview on a clean machine exits 0" "exit 0" "nonzero exit"
fi

if [ "$failures" -gt 0 ]; then
  printf '  %d failure(s)\n' "$failures"
  exit 1
fi
