#!/usr/bin/env bash
#
# Tests for script/pi-purge-legacy. Builds fake asdf, npm-global, brew-node and
# managed-install trees in a scratch dir so the removal logic runs without
# touching a real install, and fakes pgrep so the "a pi is still running"
# refusal can be exercised.
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
# a stray shim, the interim ~/.npm-global copy, the brew-node prefix and its
# wrapper, and the managed install that replaced them all.
build_tree() {
  rm -rf "$work/asdf" "$work/npm-global" "$work/pi-prefix" "$work/local-bin" "$work/pi-agent"
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

  # The brew-node layout: an npm prefix and a generated wrapper.
  mkdir -p "$work/pi-prefix/lib/node_modules/$pkg" "$work/local-bin"
  echo bundle >"$work/pi-prefix/lib/node_modules/$pkg/cli.js"
  echo wrapper >"$work/local-bin/pi"

  # The managed install: must come through untouched.
  mkdir -p "$work/pi-agent/bin" "$work/pi-agent/install/releases/1.2.0"
  echo launcher >"$work/pi-agent/bin/pi"
  echo 1.2.0 >"$work/pi-agent/install/current-version"
}

run_purge() {
  FIXTURES=$work PGREP_BIN=$work/pgrep \
    ASDF_DIR=$work/asdf NPM_GLOBAL_PREFIX=$work/npm-global PI_PREFIX=$work/pi-prefix \
    PI_WRAPPER=$work/local-bin/pi PI_CODING_AGENT_DIR=$work/pi-agent \
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
check "removes the brew-node prefix" "no" "$(exists "$work/pi-prefix")"
check "removes the brew-node wrapper" "no" "$(exists "$work/local-bin/pi")"

# --- and touches nothing else ------------------------------------------------
check "leaves the managed launcher alone" "yes" "$(exists "$work/pi-agent/bin/pi")"
check "leaves the managed releases alone" "yes" "$(exists "$work/pi-agent/install/releases/1.2.0")"
check "leaves unrelated npm packages alone" \
  "yes" "$(exists "$work/asdf/installs/nodejs/24.10.0/lib/node_modules/typescript/index.js")"
check "leaves other shims alone" "yes" "$(exists "$work/asdf/shims/node")"

# --- a managed entrypoint in ~/.local/bin is not the old wrapper ------------
# The installer links its launcher into the first of ~/bin or ~/.local/bin on
# PATH, so on some machines ~/.local/bin/pi is the live install.
build_tree
rm "$work/local-bin/pi"
ln -s ../pi-agent/bin/pi "$work/local-bin/pi"
FORCE=1 run_purge >/dev/null
check "leaves a managed entrypoint alone" "yes" "$(exists "$work/local-bin/pi")"
check "still removes the brew-node prefix beside it" "no" "$(exists "$work/pi-prefix")"

# --- refuses to sweep a tree holding the managed install --------------------
build_tree
if FIXTURES=$work PGREP_BIN=$work/pgrep ASDF_DIR=$work/asdf NPM_GLOBAL_PREFIX=$work/npm-global \
  PI_PREFIX=$work PI_WRAPPER=$work/local-bin/pi PI_CODING_AGENT_DIR=$work/pi-agent \
  FORCE=1 "$subject" >/dev/null 2>&1; then
  check "refuses a sweep containing the managed install" "nonzero exit" "exit 0"
else
  check "refuses a sweep containing the managed install" "nonzero exit" "nonzero exit"
fi
check "that refusal deletes nothing" "yes" "$(exists "$work/pi-agent/bin/pi")"

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
