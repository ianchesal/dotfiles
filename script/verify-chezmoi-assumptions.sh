#!/usr/bin/env bash
# Verifies the chezmoi behaviours the migration design depends on.
# Runs entirely in a scratch dir - never touches the real home.
#
# See docs/superpowers/specs/2026-09-11-chezmoi-migration-design.md
set -euo pipefail

CZ="${CHEZMOI:-chezmoi}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "  ok: $*"; }

R="$WORK/repo"; D="$WORK/dest"; S="$WORK/state/s.boltdb"
mkdir -p "$R/home/dot_config" "$D" "$R/nvim/lua" "$WORK/state"
printf 'home' > "$R/.chezmoiroot"

cz() { "$CZ" "$@" --source "$R" --destination "$D" --persistent-state "$S"; }

echo "1. workingTree vs sourceDir under .chezmoiroot"
[ "$(cz execute-template '{{ .chezmoi.sourceDir }}')"   = "$R/home" ] || fail "sourceDir wrong"
[ "$(cz execute-template '{{ .chezmoi.workingTree }}')" = "$R" ]      || fail "workingTree wrong"
ok "sourceDir=<repo>/home, workingTree=<repo>"

echo "2. symlink_ entry can target a DIRECTORY, alongside copied files"
echo 'return {}'      > "$R/nvim/lua/foo.lua"
echo '{"plugins":{}}' > "$R/nvim/pins.json"
printf '%s' '{{ .chezmoi.workingTree }}/nvim' > "$R/home/dot_config/symlink_nvim.tmpl"
printf 'set -g mouse on\n' > "$R/home/dot_config/tmux.conf"
cz apply
[ -L "$D/.config/nvim" ]      || fail ".config/nvim is not a symlink"
[ -f "$D/.config/tmux.conf" ] || fail "tmux.conf was not copied"
ok "directory symlink and copied file coexist"

echo "3. writes through the symlink land in the repo and are invisible to chezmoi"
echo '{"plugins":{"x":{"rev":"deadbeef"}}}' > "$D/.config/nvim/pins.json"
echo '{"x":"y"}' > "$D/.config/nvim/nvim-pack-lock.json"
grep -q deadbeef "$R/nvim/pins.json" || fail "write did not reach the repo"
[ -f "$R/nvim/nvim-pack-lock.json" ] || fail "lockfile did not reach the repo"
[ -z "$(cz status)" ] || fail "chezmoi sees nvim writes: $(cz status)"
ok "nvim writes reach the repo, chezmoi status stays clean"

echo "4. drift on a MANAGED file is caught and apply refuses to clobber"
echo 'HAND EDITED' > "$D/.config/tmux.conf"
[ -n "$(cz status)" ] || fail "drift on tmux.conf not reported"
if cz apply --error-on-conflict 2>/dev/null; then
  fail "apply --error-on-conflict succeeded despite drift"
fi
grep -q 'HAND EDITED' "$D/.config/tmux.conf" || fail "hand edit was clobbered"
ok "drift reported; --error-on-conflict refused and preserved the edit"

echo "5. apply over a live directory symlink DESTROYS untracked state"
R2="$WORK/r2"; D2="$WORK/d2"; L2="$WORK/live2"; S2="$WORK/state/s2.boltdb"
mkdir -p "$R2/home/dot_config/tmux" "$D2/.config" "$L2/plugins"
printf 'home' > "$R2/.chezmoiroot"
printf 'set -g mouse on\n' > "$R2/home/dot_config/tmux/tmux.conf"
echo 'tpm' > "$L2/plugins/tpm"
ln -s "$L2" "$D2/.config/tmux"
"$CZ" apply --source "$R2" --destination "$D2" --persistent-state "$S2"
[ -L "$D2/.config/tmux" ] && fail "symlink survived - hazard assumption wrong"
[ -e "$D2/.config/tmux/plugins" ] && fail "untracked state survived - hazard assumption wrong"
ok "confirmed: symlink replaced, untracked state lost -> cutover script is mandatory"

echo
echo "All assumptions hold for $($CZ --version | head -1)"
