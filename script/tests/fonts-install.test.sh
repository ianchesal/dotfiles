#!/usr/bin/env bash
#
# Tests for script/fonts-install. Drives the script against fake brew, xattr
# and killall so no cask is installed and no real file or daemon is touched.
#
# Run: script/tests/fonts-install.test.sh

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
subject=$here/../fonts-install

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# brew: logs installs; `info` reports two font artifacts and one non-font
# artifact, all pointing into the scratch dir.
cat >"$work/brew" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
case $1 in
  install) echo "install $*" >>"$FIXTURES/calls" ;;
  info)
    cat <<JSON
{"casks":[{"artifacts":[
  {"font":["a.ttf"],"target":"$FIXTURES/fonts/A.ttf"},
  {"font":["b.ttf"],"target":"$FIXTURES/fonts/B.ttf"},
  {"uninstall":[{"delete":"$FIXTURES/fonts/C.ttf"}]}
]}]}
JSON
    ;;
  *) echo "unexpected: $*" >&2; exit 1 ;;
esac
FAKE

# xattr: a file is quarantined while a "<file>.q" marker exists beside it.
cat >"$work/xattr" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
if [ "$1" = -d ]; then
  echo "clear ${3##*/}" >>"$FIXTURES/calls"
  rm -f "$3.q"
else
  echo com.apple.provenance
  [ -e "$1.q" ] && echo com.apple.quarantine
fi
exit 0
FAKE

cat >"$work/killall" <<'FAKE'
#!/usr/bin/env bash
echo "killall $*" >>"$FIXTURES/calls"
FAKE
chmod +x "$work/brew" "$work/xattr" "$work/killall"

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

reset_fonts() {
  rm -rf "$work/fonts" "$work/calls"
  mkdir "$work/fonts"
  touch "$work/fonts/A.ttf" "$work/fonts/B.ttf" "$work/fonts/C.ttf"
}

run_install() {
  local os=$1
  shift
  FIXTURES=$work BREW_BIN=$work/brew XATTR_BIN=$work/xattr KILLALL_BIN=$work/killall FONTS_OS=$os \
    "$subject" "$@" >"$work/out" 2>"$work/err"
}

calls() {
  [ -f "$work/calls" ] || return 0
  tr '\n' ';' <"$work/calls" | sed 's/;$//'
}

echo "fonts-install"

# --- macOS: installs each cask, clears only quarantined font targets -------
reset_fonts
touch "$work/fonts/A.ttf.q" "$work/fonts/C.ttf.q"
run_install Darwin font-one font-two
check "installs every cask, clears quarantined fonts, restarts fontd" \
  "install install --cask font-one;install install --cask font-two;clear A.ttf;killall fontd" "$(calls)"
check "leaves non-font artifacts alone" "yes" "$([ -e "$work/fonts/C.ttf.q" ] && echo yes || echo no)"

# --- macOS rerun: nothing quarantined, so fontd is left running ------------
reset_fonts
run_install Darwin font-one
check "no quarantine means no fontd restart" "install install --cask font-one" "$(calls)"

# --- Linux: install only, no xattr work ------------------------------------
reset_fonts
touch "$work/fonts/A.ttf.q"
run_install Linux font-one
check "skips the macOS fix elsewhere" "install install --cask font-one" "$(calls)"

# --- no casks is a usage error ---------------------------------------------
if run_install Darwin; then status=0; else status=$?; fi
check "no arguments exits 1" "1" "$status"

if [ "$failures" -gt 0 ]; then
  echo "$failures failure(s)"
  exit 1
fi
