#!/usr/bin/env bash
#
# Tests for script/asdf-prune. Drives the script against a fake asdf so the
# pruning logic can be exercised without touching real toolchains.
#
# Run: script/tests/asdf-prune.test.sh

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
subject=$here/../asdf-prune

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Fake asdf: `plugin list` and `list <plugin>` read fixture files, `uninstall`
# appends to a log so the test can assert on what would have been removed.
cat >"$work/asdf" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
case "$1 ${2:-}" in
  "plugin list") cat "$FIXTURES/plugins" ;;
  "list "*)      cat "$FIXTURES/installed.$2" 2>/dev/null || { echo "no compatible versions installed" >&2; exit 1; } ;;
  "uninstall "*) echo "$2 $3" >>"$FIXTURES/uninstalled" ;;
  *) echo "unexpected: $*" >&2; exit 1 ;;
esac
FAKE
chmod +x "$work/asdf"

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

# One fixture set per scenario, then FORCE=1 so the uninstall log is populated.
run_prune() {
  FIXTURES=$work ASDF_BIN=$work/asdf TOOL_VERSIONS=$work/.tool-versions FORCE=1 \
    "$subject" "$@"
}

reset_fixtures() { rm -f "$work"/installed.* "$work"/plugins "$work"/uninstalled "$work"/.tool-versions; }

echo "asdf-prune"

# --- pinned plugin prunes everything strictly older than the pin -------------
reset_fixtures
echo "ruby" >"$work/plugins"
printf '  3.2.0\n  3.3.0\n *4.0.6\n  4.1.0\n' >"$work/installed.ruby"
echo "ruby 4.0.6" >"$work/.tool-versions"
run_prune >/dev/null
check "prunes below the pin, keeps the pin and newer" \
  "ruby 3.2.0 ruby 3.3.0" "$(tr '\n' ' ' <"$work/uninstalled" | sed 's/ $//')"

# --- unpinned plugin collapses to the newest install ------------------------
reset_fixtures
echo "golang" >"$work/plugins"
printf '  1.22.0\n  1.23.0\n *1.24.0\n' >"$work/installed.golang"
: >"$work/.tool-versions"
run_prune >/dev/null
check "unpinned keeps only the newest" \
  "golang 1.22.0 golang 1.23.0" "$(tr '\n' ' ' <"$work/uninstalled" | sed 's/ $//')"

# --- a pin sort -V cannot order disables pruning for that plugin ------------
reset_fixtures
echo "nodejs" >"$work/plugins"
printf '  20.0.0\n  22.0.0\n' >"$work/installed.nodejs"
echo "nodejs ref:abc123" >"$work/.tool-versions"
run_prune >/dev/null
check "uncomparable pin prunes nothing" "" "$(cat "$work/uninstalled" 2>/dev/null || true)"

# --- uncomparable installs are reported but never removed -------------------
reset_fixtures
echo "ruby" >"$work/plugins"
printf '  3.2.0\n *4.0.6\n  system\n  jruby-9.4.5.0\n' >"$work/installed.ruby"
echo "ruby 4.0.6" >"$work/.tool-versions"
output=$(run_prune)
check "uncomparable installs are not removed" "ruby 3.2.0" "$(tr '\n' ' ' <"$work/uninstalled" | sed 's/ $//')"
check "uncomparable installs are reported" "2" \
  "$(grep -c 'uncomparable version, left alone' <<<"$output")"

# --- multi-version pin uses the oldest as the threshold ---------------------
reset_fixtures
echo "ruby" >"$work/plugins"
printf '  3.1.0\n  3.2.0\n  3.3.0\n *4.0.6\n' >"$work/installed.ruby"
echo "ruby 4.0.6 3.2.0" >"$work/.tool-versions"
run_prune >/dev/null
check "oldest pinned version is the threshold" "ruby 3.1.0" \
  "$(tr '\n' ' ' <"$work/uninstalled" | sed 's/ $//')"

# --- a plugin with no comparable install has no threshold, so prunes nothing -
reset_fixtures
echo "weird" >"$work/plugins"
printf '  system\n' >"$work/installed.weird"
: >"$work/.tool-versions"
output=$(run_prune)
check "no comparable install prunes nothing" "" "$(cat "$work/uninstalled" 2>/dev/null || true)"
check "no comparable install reports no version in use" "1" \
  "$(grep -c 'no version in use' <<<"$output")"

# --- comments in .tool-versions are ignored ---------------------------------
reset_fixtures
echo "ruby" >"$work/plugins"
printf '  3.2.0\n *4.0.6\n' >"$work/installed.ruby"
printf 'ruby 4.0.6 # pinned for work\n' >"$work/.tool-versions"
run_prune >/dev/null
check "trailing comments are stripped from pins" "ruby 3.2.0" \
  "$(tr '\n' ' ' <"$work/uninstalled" | sed 's/ $//')"

# --- --preview never uninstalls ---------------------------------------------
reset_fixtures
echo "ruby" >"$work/plugins"
printf '  3.2.0\n *4.0.6\n' >"$work/installed.ruby"
echo "ruby 4.0.6" >"$work/.tool-versions"
run_prune --preview >/dev/null
check "--preview uninstalls nothing" "" "$(cat "$work/uninstalled" 2>/dev/null || true)"

# --- declining the prompt uninstalls nothing --------------------------------
reset_fixtures
echo "ruby" >"$work/plugins"
printf '  3.2.0\n *4.0.6\n' >"$work/installed.ruby"
echo "ruby 4.0.6" >"$work/.tool-versions"
echo n | FIXTURES=$work ASDF_BIN=$work/asdf TOOL_VERSIONS=$work/.tool-versions \
  "$subject" >/dev/null
check "answering no uninstalls nothing" "" "$(cat "$work/uninstalled" 2>/dev/null || true)"

if [ "$failures" -gt 0 ]; then
  printf '\n%d failure(s)\n' "$failures"
  exit 1
fi
printf '\nall passed\n'
