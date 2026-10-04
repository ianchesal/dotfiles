# SSH Keys and Config from 1Password Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Private SSH keys live only in 1Password, and every personal machine gets the same `~/.ssh/config` from this repo plus 1Password-held host blocks, while work machines and the cloud workstation are left alone.

**Architecture:** chezmoi deploys a public skeleton `~/.ssh/config` (LAN hosts, GitHub, a socket-guarded `IdentityAgent`) plus the public keys it pins. `script/ssh-config-sync` (run by `just ssh::sync` and the `update` fan-out) pulls Secure Notes tagged `ssh-config` out of 1Password into `~/.ssh/config.d/`. `~/.1password/agent.sock` is the one agent path everywhere: native on Linux, a chezmoi symlink on macOS, and a `socat`/`npiperelay.exe` relay on WSL started from zsh.

**Tech Stack:** bash (3.2-compatible), `jq`, 1Password CLI `op` 2.x, chezmoi templates, `just`, zsh, OpenSSH config (`Match exec`), `socat` + `npiperelay.exe` + `flock` on WSL.

**Spec:** `docs/superpowers/specs/2026-10-04-ssh-1password-design.md`

## Global Constraints

- Shell: bash with `set -euo pipefail`; must pass `shellcheck --severity=warning`. Keep scripts bash 3.2-compatible (no `mapfile`, no associative arrays) — this one runs on macOS.
- justfiles must pass `just --fmt --check`; every recipe has a `#` doc comment on the line directly above it; each module repeats `set shell := ["bash", "-eu", "-o", "pipefail", "-c"]`; module recipes reach the repo through `$REPO`, never a relative path.
- Line length limit 160; 2-space indentation; prefer single quotes unless interpolating.
- chezmoi: `dot_` at every level; source state root is `home/`; in templates the repo root is `.chezmoi.workingTree`. **From this worktree always pass `--source "$(git rev-parse --show-toplevel)"`** and scope the path; never run an unscoped `chezmoi apply`.
- Never write a private key, an `OP_SESSION_*` value, or a public IP into the repo. Public keys and `192.168.1.x` hosts are fine.
- Work-machine test is the file `~/.work_machine`; gcw test is the directory `/etc/workstation-startup.d`. Test files, never exported variables.
- Exact strings from the spec:
  - Managed header: `# managed by ssh-config-sync -- edit in 1Password: <title>`
  - Signed-out notice: `1Password CLI not signed in -- skipping. Run: eval "$(op signin)" && just ssh::sync`
  - macOS-over-SSH notice: `1Password would prompt on the Mac's display -- skipping over SSH. Run 'just ssh::sync' at the console.`
  - Title regex: `^[A-Za-z0-9][A-Za-z0-9._-]*$`
  - Defaults: `OP_VAULT=Private`, `OP_TAG=ssh-config`, `OP_TIMEOUT=60`.
- Do **not** run any step of the spec's §4 migration runbook (deleting keys, applying to the real `~/.ssh`, Windows service changes). Those are Ian's.

## Review Focus

1. **A hand-written `config.d/<name>` that collides with a 1Password note title** — Ian expects his hand-written file to survive; the sync must warn and skip that title, never overwrite an unmanaged file. (Test in Task 1.)
2. **A note body pasted with Windows CRLF line endings** — ssh rejects `\r` in config lines; the sync should strip `\r` so a note edited on the Windows 1Password app still works. (Test in Task 1.)
3. **`op item list` printing nothing (not `[]`) when no item has the tag** — must be treated as zero items (and hit the zero-items prune guard), not as malformed JSON. (Test in Task 1.)
4. **A fresh machine with no `~/.ssh` yet** (sync run before `chezmoi apply`) — the sync must create `~/.ssh` 0700 and `config.d` 0700, not world-readable dirs from the default umask. (Test in Task 1.)
5. **`op` writing a warning to stderr on success** (e.g. an "update available" notice) — must not be mistaken for failure or leak into parsed JSON. (Test in Task 1.)

---

### Task 1: `script/ssh-config-sync` with tests

**Files:**
- Create: `script/ssh-config-sync` (mode 0755)
- Create: `script/tests/ssh-config-sync.test.sh` (mode 0755)
- Modify: `justfile` (the `lint` recipe's shellcheck list)

**Interfaces:**
- Consumes: nothing.
- Produces: an executable `script/ssh-config-sync` taking no arguments. Env seams: `OP_BIN`, `OP_ACCOUNT`, `OP_VAULT`, `OP_TAG`, `OP_TIMEOUT`, `SSH_CONFIG_D`, `WORK_MACHINE_FLAG`, `GCW_MARKER`, `UNAME_S`. Exit 0 on success or any skip; exit 1 on a real fault. Task 2's `just ssh::sync` calls it as `"$REPO/script/ssh-config-sync"`.

- [ ] **Step 1: Write the test file**

`script/tests/ssh-config-sync.test.sh`:

```bash
#!/usr/bin/env bash
#
# Tests for script/ssh-config-sync. Drives the script against a fake `op` so
# the fetch/validate/write/prune logic runs without touching 1Password or the
# real ~/.ssh.
#
# Run: script/tests/ssh-config-sync.test.sh

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
subject=$here/../ssh-config-sync

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fx=$work/fixtures

cat >"$work/op" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >>"$FIXTURES/calls"
[ -f "$FIXTURES/stderr-noise" ] && echo 'A new version of 1Password CLI is available' >&2
if [ "${1:-}" = --account ]; then shift 2; fi
case "${1:-}" in
  whoami)
    [ -f "$FIXTURES/whoami-hang" ] && exec sleep 30
    if [ -f "$FIXTURES/whoami-fail" ]; then
      echo '[ERROR] You are not currently signed in' >&2
      exit 1
    fi
    echo 'URL: https://example.1password.com'
    exit 0
    ;;
  item)
    case "${2:-}" in
      list)
        [ -f "$FIXTURES/list-fail" ] && exit 1
        cat "$FIXTURES/list.json"
        exit 0
        ;;
      get)
        [ -f "$FIXTURES/get-fail-$3" ] && exit 1
        cat "$FIXTURES/items/$3.json"
        exit 0
        ;;
    esac
    ;;
esac
echo "unexpected: $*" >&2
exit 1
FAKE
chmod +x "$work/op"

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

mode_of() { stat -c %a "$1" 2>/dev/null || stat -f %Lp "$1"; }

reset() {
  rm -rf "${fx:?}" "${work:?}/home"
  mkdir -p "$fx/items" "$work/home/.ssh"
  echo '[]' >"$fx/list.json"
}

add_item() {
  local id=$1 title=$2 body=$3
  jq -n --arg id "$id" --arg t "$title" --arg b "$body" \
    '{id: $id, title: $t, fields: [{id: "notesPlain", label: "notesPlain", value: $b}]}' >"$fx/items/$id.json"
  jq --arg id "$id" --arg t "$title" '. + [{id: $id, title: $t}]' "$fx/list.json" >"$fx/list.tmp"
  mv "$fx/list.tmp" "$fx/list.json"
}

cfgd=$work/home/.ssh/config.d

# Runs the script with every seam pointed into $work. Extra VAR=value pairs
# can be passed as arguments and are applied via env.
run_sync() {
  rm -f "$fx/calls"
  env -u SSH_CONNECTION FIXTURES="$fx" OP_BIN="$work/op" OP_TIMEOUT=2 \
    SSH_CONFIG_D="$cfgd" WORK_MACHINE_FLAG="$work/no-such-flag" \
    GCW_MARKER="$work/no-such-gcw" UNAME_S=Linux "$@" "$subject" >"$work/out" 2>"$work/err"
}

exit_of() { if run_sync "$@"; then echo 0; else echo nonzero; fi; }
header() { printf '# managed by ssh-config-sync -- edit in 1Password: %s' "$1"; }
ls_cfgd() { [ -d "$cfgd" ] && (cd "$cfgd" && ls -A | tr '\n' ' ' | sed 's/ $//'); return 0; }

echo "ssh-config-sync"

# --- writes each item with the header, 0600 file, 0700 dir -------------------
reset
add_item a1 fractal $'Host fractal-host2\n  HostName 203.0.113.7'
add_item a2 chesal.net $'Host chesal.net\n  User root'
check "happy path exits 0" 0 "$(exit_of)"
check "writes both files" "chesal.net fractal" "$(ls_cfgd)"
check "first line is the header" "$(header fractal)" "$(head -1 "$cfgd/fractal")"
check "body follows the header" "  HostName 203.0.113.7" "$(sed -n 3p "$cfgd/fractal")"
check "file mode 0600" 600 "$(mode_of "$cfgd/fractal")"
check "dir mode 0700" 700 "$(mode_of "$cfgd")"

# --- rerun is idempotent -----------------------------------------------------
before=$(cat "$cfgd/fractal")
run_sync
check "rerun leaves content unchanged" "$before" "$(cat "$cfgd/fractal")"

# --- prunes a managed file whose item is gone, keeps unmanaged files ---------
printf 'Host handmade\n' >"$cfgd/handmade"
reset_keep() { rm -rf "${fx:?}"; mkdir -p "$fx/items"; echo '[]' >"$fx/list.json"; }
reset_keep
add_item a1 fractal $'Host fractal-host2'
run_sync
check "prunes the stale managed file" "fractal handmade" "$(ls_cfgd)"

# --- zero items while managed files exist: warn, prune nothing ---------------
reset_keep
check "zero items exits 0" 0 "$(exit_of)"
check "zero items prunes nothing" "fractal handmade" "$(ls_cfgd)"
check "zero items warns" yes "$(grep -q 'refusing to prune' "$work/err" && echo yes || echo no)"

# --- op printing nothing for an empty list counts as zero items --------------
: >"$fx/list.json"
check "empty list output exits 0" 0 "$(exit_of)"
check "empty list output prunes nothing" "fractal handmade" "$(ls_cfgd)"

# --- never overwrites an unmanaged file with the same name -------------------
reset
printf 'Host mine\n' >"$work/home/.ssh/placeholder"
mkdir -p "$cfgd"
printf 'Host handmade\n' >"$cfgd/handmade"
add_item a1 handmade $'Host from-1password'
add_item a2 other $'Host other'
check "collision exits 0" 0 "$(exit_of)"
check "unmanaged file untouched" "Host handmade" "$(cat "$cfgd/handmade")"
check "collision warns" yes "$(grep -q "not managed by ssh-config-sync" "$work/err" && echo yes || echo no)"
check "other item still written" "$(header other)" "$(head -1 "$cfgd/other")"

# --- bad titles are skipped with a warning -----------------------------------
reset
add_item b1 . 'Host dot'
add_item b2 .. 'Host dotdot'
add_item b3 .hidden 'Host hidden'
add_item b4 'has space' 'Host space'
add_item b5 good 'Host good'
check "bad titles exit 0" 0 "$(exit_of)"
check "only the good title is written" good "$(ls_cfgd)"
check "bad title warns" 4 "$(grep -c 'invalid title' "$work/err")"
check "nothing escaped config.d" "config.d" "$(cd "$work/home/.ssh" && ls -A | tr '\n' ' ' | sed 's/ $//')"

# --- duplicate titles are a fault: nothing written ---------------------------
reset
add_item d1 dup 'Host one'
add_item d2 dup 'Host two'
add_item d3 fine 'Host fine'
check "duplicate titles exit nonzero" nonzero "$(exit_of)"
check "duplicate titles write nothing" "" "$(ls_cfgd)"

# --- empty body is skipped with a warning ------------------------------------
reset
add_item e1 empty ''
add_item e2 full 'Host full'
check "empty body exits 0" 0 "$(exit_of)"
check "empty body not written" full "$(ls_cfgd)"
check "empty body warns" yes "$(grep -q 'empty note' "$work/err" && echo yes || echo no)"

# --- CRLF bodies are normalised ------------------------------------------------
reset
add_item c1 crlf $'Host crlf\r\n  User ian\r'
run_sync
check "CR stripped" 0 "$(grep -c $'\r' "$cfgd/crlf" || true)"

# --- stderr noise from a successful op is ignored ------------------------------
reset
touch "$fx/stderr-noise"
add_item n1 noisy 'Host noisy'
check "stderr noise exits 0" 0 "$(exit_of)"
check "stderr noise still writes" "Host noisy" "$(sed -n 2p "$cfgd/noisy")"

# --- fresh machine: no ~/.ssh yet ----------------------------------------------
reset
rm -rf "$work/home/.ssh"
add_item f1 fresh 'Host fresh'
run_sync
check "creates ~/.ssh 0700" 700 "$(mode_of "$work/home/.ssh")"
check "creates config.d 0700" 700 "$(mode_of "$cfgd")"

# --- skips: no op, work machine, gcw, macOS over SSH -----------------------------
reset
add_item s1 skipme 'Host skipme'
check "absent op skips cleanly" 0 "$(exit_of OP_BIN="$work/definitely-not-op")"
check "absent op writes nothing" "" "$(ls_cfgd)"

touch "$work/flag"
check "work machine skips" 0 "$(exit_of WORK_MACHINE_FLAG="$work/flag")"
check "work machine never calls op" no "$([ -s "$fx/calls" ] && echo yes || echo no)"

mkdir -p "$work/gcw"
check "gcw skips" 0 "$(exit_of GCW_MARKER="$work/gcw")"
check "gcw never calls op" no "$([ -s "$fx/calls" ] && echo yes || echo no)"

check "macOS over SSH skips" 0 "$(exit_of UNAME_S=Darwin SSH_CONNECTION='10.0.0.1 1 10.0.0.2 22')"
check "macOS over SSH never calls op" no "$([ -s "$fx/calls" ] && echo yes || echo no)"
check "macOS over SSH notice" yes \
  "$(grep -qF "1Password would prompt on the Mac's display -- skipping over SSH. Run 'just ssh::sync' at the console." "$work/err" && echo yes || echo no)"

# Linux over SSH is fine: op there uses the daemon session, no GUI prompt.
check "Linux over SSH still syncs" 0 "$(exit_of SSH_CONNECTION='10.0.0.1 1 10.0.0.2 22')"
check "Linux over SSH writes" skipme "$(ls_cfgd)"

# --- signed out: exit 0, notice, nothing touched --------------------------------
reset
add_item w1 locked 'Host locked'
touch "$fx/whoami-fail"
check "signed out exits 0" 0 "$(exit_of)"
check "signed out writes nothing" "" "$(ls_cfgd)"
check "signed out notice" yes \
  "$(grep -qF '1Password CLI not signed in -- skipping. Run: eval "$(op signin)" && just ssh::sync' "$work/err" && echo yes || echo no)"

# --- whoami hanging past OP_TIMEOUT: exit 0, nothing touched ---------------------
reset
add_item h1 hung 'Host hung'
touch "$fx/whoami-hang"
start=$(date +%s)
check "hung whoami exits 0" 0 "$(exit_of OP_TIMEOUT=1)"
elapsed=$(($(date +%s) - start))
check "hung whoami gives up within the timeout" yes "$([ "$elapsed" -lt 10 ] && echo yes || echo no)"
check "hung whoami writes nothing" "" "$(ls_cfgd)"

# --- op failure after the preflight: nonzero, nothing changed ---------------------
reset
mkdir -p "$cfgd"
printf '%s\nHost old\n' "$(header old)" >"$cfgd/old"
add_item g1 one 'Host one'
add_item g2 two 'Host two'
touch "$fx/get-fail-g2"
check "get failure exits nonzero" nonzero "$(exit_of)"
check "get failure writes and prunes nothing" old "$(ls_cfgd)"

rm -f "$fx/get-fail-g2"
touch "$fx/list-fail"
check "list failure exits nonzero" nonzero "$(exit_of)"
check "list failure changes nothing" old "$(ls_cfgd)"

# --- OP_ACCOUNT is passed to every op call -----------------------------------------
reset
add_item k1 acct 'Host acct'
run_sync OP_ACCOUNT=chesal
check "every call carries --account" 0 "$(grep -cv '^--account chesal ' "$fx/calls" || true)"
check "account calls happened" yes "$([ -s "$fx/calls" ] && echo yes || echo no)"

if [ "$failures" -gt 0 ]; then
  printf '  %d failure(s)\n' "$failures"
  exit 1
fi
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `chmod +x script/tests/ssh-config-sync.test.sh && script/tests/ssh-config-sync.test.sh`
Expected: FAIL — every `exit_of` reports `nonzero` because `script/ssh-config-sync` does not exist; the run ends with `N failure(s)` and exit 1.

- [ ] **Step 3: Write the script**

`script/ssh-config-sync`:

```bash
#!/usr/bin/env bash
#
# Pull ~/.ssh/config.d/ host blocks out of 1Password.
#
# Host entries too sensitive for this public repo (public IPs, ports, users)
# live in 1Password as Secure Notes tagged `ssh-config` in the Private vault.
# The item title is the file name; the note body is the raw `Host ...` block.
# ~/.ssh/config (chezmoi-managed) does `Include config.d/*`, so whatever lands
# here takes effect on the next ssh.
#
# Runs from `just ssh::sync` and the `just update` fan-out, so it must never
# fail or hang `dfu` over a locked or absent 1Password:
#   - no op, a work machine, the cloud workstation, or macOS over SSH (where
#     the app's auth prompt lands on a display nobody can see) -> skip, exit 0
#   - `op whoami` fails or exceeds OP_TIMEOUT                     -> skip, exit 0
#   - anything failing AFTER that preflight is a real fault       -> exit 1
# Everything is fetched and validated before anything is written, so a fault
# leaves config.d exactly as it was.
#
# Only files whose first line is the managed header are ever overwritten or
# pruned; hand-written files in config.d are left alone.
#
# Seams for script/tests/ssh-config-sync.test.sh:
#   OP_BIN            -- op executable (default: op from PATH)
#   OP_ACCOUNT        -- passed as --account when set
#   OP_VAULT          -- vault to read (default: Private)
#   OP_TAG            -- tag selecting the notes (default: ssh-config)
#   OP_TIMEOUT        -- seconds to wait for `op whoami` (default: 60)
#   SSH_CONFIG_D      -- destination (default: ~/.ssh/config.d)
#   WORK_MACHINE_FLAG -- work-machine flag file (default: ~/.work_machine)
#   GCW_MARKER        -- cloud-workstation marker dir (default: /etc/workstation-startup.d)
#   UNAME_S           -- kernel name (default: uname -s)

set -euo pipefail

op_bin=${OP_BIN:-op}
vault=${OP_VAULT:-Private}
tag=${OP_TAG:-ssh-config}
op_timeout=${OP_TIMEOUT:-60}
config_d=${SSH_CONFIG_D:-$HOME/.ssh/config.d}
work_flag=${WORK_MACHINE_FLAG:-$HOME/.work_machine}
gcw_marker=${GCW_MARKER:-/etc/workstation-startup.d}
uname_s=${UNAME_S:-$(uname -s)}

header_prefix='# managed by ssh-config-sync -- edit in 1Password: '

skip() {
  printf '%s\n' "$1" >&2
  exit 0
}
fault() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}
warn() { printf 'WARNING: %s\n' "$1" >&2; }

run_op() {
  if [ -n "${OP_ACCOUNT:-}" ]; then
    "$op_bin" --account "$OP_ACCOUNT" "$@"
  else
    "$op_bin" "$@"
  fi
}

# Run "$@" with a deadline. macOS has no timeout(1), so poll instead; a poll
# loop also leaves no watchdog process behind holding the caller's pipes.
with_timeout() {
  local secs=$1 pid ticks=0
  shift
  "$@" &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$ticks" -ge $((secs * 10)) ]; then
      kill -TERM "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      return 124
    fi
    sleep 0.1
    ticks=$((ticks + 1))
  done
  wait "$pid"
}

is_managed() {
  local first=''
  [ -f "$1" ] || return 1
  IFS= read -r first <"$1" || true
  case $first in "$header_prefix"*) return 0 ;; esac
  return 1
}

# --- skips that must not touch op at all ---------------------------------------
[ -f "$work_flag" ] && skip "Skipping ssh-config-sync -- work machine ($work_flag exists)"
[ -d "$gcw_marker" ] && skip 'Skipping ssh-config-sync -- cloud workstation'
command -v "$op_bin" >/dev/null 2>&1 || skip 'Skipping ssh-config-sync -- no op command found'
if [ "$uname_s" = Darwin ] && [ -n "${SSH_CONNECTION:-}" ]; then
  skip "1Password would prompt on the Mac's display -- skipping over SSH. Run 'just ssh::sync' at the console."
fi

# --- preflight: signed in? ------------------------------------------------------
if ! with_timeout "$op_timeout" run_op whoami >/dev/null 2>&1; then
  skip '1Password CLI not signed in -- skipping. Run: eval "$(op signin)" && just ssh::sync'
fi

# --- fetch and validate everything before writing anything -----------------------
staging=$(mktemp -d)
trap 'rm -rf "$staging"' EXIT

list_json=$(run_op item list --vault "$vault" --tags "$tag" --format json) || fault 'op item list failed'
[ -n "$list_json" ] || list_json='[]'
rows=$(printf '%s' "$list_json" | jq -r '.[] | [.id, .title] | @tsv') || fault 'could not parse op item list output'

titles=''
while IFS=$'\t' read -r id title; do
  [ -n "${id:-}" ] || continue
  if ! grep -Eq '^[A-Za-z0-9][A-Za-z0-9._-]*$' <<<"$title"; then
    warn "invalid title '$title' (item $id) -- skipped"
    continue
  fi
  titles="$titles$title"$'\n'
  printf '%s\n' "$id" >"$staging/$title.id"
done <<<"$rows"

dups=$(printf '%s' "$titles" | sort | uniq -d)
[ -z "$dups" ] || fault "duplicate titles in 1Password: $(printf '%s' "$dups" | tr '\n' ' ')-- nothing written"

written=''
while IFS= read -r title; do
  [ -n "$title" ] || continue
  id=$(cat "$staging/$title.id")
  item_json=$(run_op item get "$id" --vault "$vault" --format json) || fault "op item get failed for '$title'"
  body=$(printf '%s' "$item_json" | jq -r '.fields[]? | select(.id == "notesPlain") | .value // ""') ||
    fault "could not parse note '$title'"
  body=$(printf '%s' "$body" | tr -d '\r')
  if [ -z "$body" ]; then
    warn "empty note '$title' -- skipped"
    continue
  fi
  if [ -e "$config_d/$title" ] && ! is_managed "$config_d/$title"; then
    warn "$config_d/$title exists and is not managed by ssh-config-sync -- skipped"
    continue
  fi
  printf '%s%s\n%s\n' "$header_prefix" "$title" "$body" >"$staging/$title"
  written="$written$title"$'\n'
done <<<"$titles"

# --- write ------------------------------------------------------------------------
(
  umask 077
  mkdir -p "$(dirname "$config_d")" "$config_d"
)
chmod 700 "$config_d"

while IFS= read -r title; do
  [ -n "$title" ] || continue
  tmp=$(mktemp "$config_d/.$title.XXXXXX")
  cat "$staging/$title" >"$tmp"
  chmod 600 "$tmp"
  mv -f "$tmp" "$config_d/$title"
  echo "Wrote $config_d/$title"
done <<<"$written"

# --- prune ------------------------------------------------------------------------
if [ -z "$written" ]; then
  for f in "$config_d"/*; do
    if is_managed "$f"; then
      warn "1Password returned no '$tag' notes but managed files exist -- refusing to prune"
      break
    fi
  done
  exit 0
fi

for f in "$config_d"/*; do
  is_managed "$f" || continue
  name=${f##*/}
  grep -qxF "$name" <<<"$written" && continue
  rm -f "$f"
  echo "Removed $f (no longer in 1Password)"
done
```

Note on the collision rule: a title skipped because its file is unmanaged is not in `written`, and the unmanaged file is not pruned (prune only touches managed files), so it survives.

- [ ] **Step 4: Make it executable and run the tests**

Run: `chmod +x script/ssh-config-sync && script/tests/ssh-config-sync.test.sh`
Expected: every line `ok`, exit 0. If "hung whoami gives up within the timeout" fails, check that `with_timeout` is killing the fake's `exec sleep 30`.

- [ ] **Step 5: Add the script to `just lint`**

In `justfile`, the `lint` recipe's shellcheck list, change:

```
      script/brew-trust script/pi-purge-legacy script/ohmyposh-preview \
```

to:

```
      script/brew-trust script/pi-purge-legacy script/ohmyposh-preview script/ssh-config-sync \
```

- [ ] **Step 6: Run lint and the whole script suite**

Run: `just lint && just test-scripts`
Expected: no shellcheck findings; all suites print only `ok` lines.

- [ ] **Step 7: Commit**

```bash
git add script/ssh-config-sync script/tests/ssh-config-sync.test.sh justfile
git commit -m 'Add ssh-config-sync to pull ssh host blocks from 1Password

Co-Authored-By: Claude <noreply@anthropic.com>'
```

---

### Task 2: `just ssh::sync`, the update fan-out, and the Brewfile

**Files:**
- Create: `just/ssh.just`
- Modify: `justfile` (add `mod ssh`, extend `update`)
- Modify: `brew/Brewfile` (add `jq`, `socat`, `cask "1password-cli"`)

**Interfaces:**
- Consumes: `script/ssh-config-sync` from Task 1.
- Produces: the `ssh::sync` recipe, referenced by Task 6's docs.

- [ ] **Step 1: Create `just/ssh.just`**

```just
set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# ~/.ssh/config is chezmoi-managed and public; host blocks that must not be
# published (public IPs, ports) live in 1Password as Secure Notes tagged
# `ssh-config` and land in ~/.ssh/config.d/ via script/ssh-config-sync. The
# script skips quietly on work machines, the cloud workstation, a locked or
# signed-out 1Password, and macOS over SSH, so it is safe in the update fan-out.

# Pull ~/.ssh/config.d host blocks out of 1Password
sync:
    @"$REPO/script/ssh-config-sync"
```

- [ ] **Step 2: Wire it into the root justfile**

In `justfile`, between `mod shell 'just/shell.just'` and `mod tmux 'just/tmux.just'`, add:

```just
mod ssh 'just/ssh.just'
```

Change the `update` line to append `ssh::sync`:

```just
update: brew::update asdf::update rust::update claude::update pi::update git::update gcloud::update ytdlp::update gem::cleanup ohmyposh::check-update ssh::sync
```

(Leave the doc comment above `update` as it is.)

- [ ] **Step 3: Add the Brewfile entries**

In `brew/Brewfile`, keeping the alphabetical order of the `brew` block:
- add `brew "jq"` between `brew "git-delta"` and `brew "just"`;
- add `brew "socat"` between `brew "shellcheck"` and `brew "tmux"`;
- add `cask "1password-cli"` as the first `cask` line, directly above `cask "aerospace" if OS.mac?`, **with no OS guard** (the cask works on Linux; this WSL box already runs it).

Do not add `cask "1password"` (the app): `brew bundle` fails with "It seems there is already an App at …" when it was installed outside Homebrew.

- [ ] **Step 4: Verify**

Run:
```bash
just --fmt --check --justfile "$PWD/justfile"
just --list --list-submodules | grep -A1 '^    ssh::'
just ssh::sync
brew bundle check --verbose --file=brew/Brewfile 2>&1 | grep -E 'jq|socat|1password' || echo 'all three satisfied'
```
Expected: fmt check silent; `ssh::sync` listed with "Pull ~/.ssh/config.d host blocks out of 1Password"; `just ssh::sync` either prints the signed-out notice or runs and prints the zero-items line / nothing (no notes are tagged yet — **this writes into the real `~/.ssh/config.d` only if notes exist; none do yet, so nothing is written**); `brew bundle check` lists `jq`/`socat` as missing on this box (expected — installing them is runbook step 3, not this task).

- [ ] **Step 5: Commit**

```bash
git add just/ssh.just justfile brew/Brewfile
git commit -m 'Add just ssh::sync and its Brewfile dependencies

Co-Authored-By: Claude <noreply@anthropic.com>'
```

---

### Task 3: chezmoi source state — `.chezmoiignore`, `~/.ssh/config`, public keys, macOS socket symlink

**Files:**
- Create: `home/.chezmoiignore`
- Create: `home/private_dot_ssh/private_config`
- Create: `home/private_dot_ssh/{rpi-basement-1,tranquility,synology01,fractal-audio,digitalocean,github-personal,dads-gaming-pc}.pub`
- Create: `home/private_dot_1password/symlink_agent.sock.tmpl`

**Interfaces:**
- Consumes: nothing.
- Produces: `~/.ssh/config` whose first line is `# Managed by chezmoi from ianchesal/dotfiles (home/private_dot_ssh/private_config)` — Task 5's doctor check greps for `Managed by chezmoi from ianchesal/dotfiles`. `~/.1password/agent.sock` path used by Task 4.

- [ ] **Step 1: Write `home/.chezmoiignore`**

```
{{- /*
  Work machines and the cloud workstation keep their own ~/.ssh: the skeleton
  config and keys are for personal machines only. This is a deliberate
  exception to "every config deploys everywhere" (see AGENTS.md). destDir, not
  homeDir, so a scratch --destination can exercise both branches.
*/ -}}
{{- if or (stat (joinPath .chezmoi.destDir ".work_machine")) (stat "/etc/workstation-startup.d") }}
.ssh
.ssh/**
{{- end }}
{{- /*
  ~/.1password/agent.sock is a symlink only on macOS. On Linux 1Password
  creates the socket itself, and on WSL the zsh relay serves it -- chezmoi
  must never touch it there.
*/ -}}
{{- if ne .chezmoi.os "darwin" }}
.1password
.1password/**
{{- end }}
```

- [ ] **Step 2: Write `home/private_dot_ssh/private_config`**

```
# Managed by chezmoi from ianchesal/dotfiles (home/private_dot_ssh/private_config)
# Edit there and `chezmoi apply`; local edits are overwritten.
#
# Host blocks that must stay out of the public repo live in 1Password as Secure
# Notes tagged `ssh-config`; `just ssh::sync` writes them to config.d/. They are
# included first because ssh keeps the first value it sees for each option.
Include config.d/*

# Keys live in 1Password; each IdentityFile is the PUBLIC half, which tells the
# agent which key to sign with. IdentitiesOnly stops the agent offering all of
# its keys and tripping the server's MaxAuthTries.

# password auth
Host imac
  HostName 192.168.1.104
  User ian
  PubkeyAuthentication no

Host rpi-basement-1
  HostName 192.168.1.3
  User root
  IdentityFile ~/.ssh/rpi-basement-1.pub
  IdentitiesOnly yes

Host tranquility
  HostName 192.168.1.26
  User ian
  IdentityFile ~/.ssh/tranquility.pub
  IdentitiesOnly yes

Host synology01
  HostName 192.168.1.4
  Port 2201
  User ian
  IdentityFile ~/.ssh/synology01.pub
  IdentitiesOnly yes

# password auth
Host udm-pro
  HostName 192.168.1.1
  User root
  PubkeyAuthentication no

Host fractal-devenv
  HostName 192.168.1.222
  User ian
  IdentityFile ~/.ssh/dads-gaming-pc.pub
  IdentitiesOnly yes

Host github.com
  User git
  IdentityFile ~/.ssh/github-personal.pub
  IdentitiesOnly yes

# 1Password's agent, only when its socket exists. An unconditional
# IdentityAgent would silently disable a forwarded or hand-started agent
# (it overrides SSH_AUTH_SOCK) on any box without 1Password.
# ~/.1password/agent.sock: native on Linux, a chezmoi symlink on macOS, the
# zsh relay on WSL (zshrc.d/1password.zsh).
Match exec "test -S ~/.1password/agent.sock"
  IdentityAgent ~/.1password/agent.sock
```

- [ ] **Step 3: Export the public keys from 1Password**

Needs `op` signed in (`eval "$(op signin)"` if `op whoami` fails). Run from the repo root:

```bash
export_pub() {
  op item get "$1" --vault Private --fields 'public key' >"home/private_dot_ssh/$2.pub"
}
export_pub 'rpi-basement-1'     rpi-basement-1
export_pub 'ian@tranquility'    tranquility
export_pub 'synology01'         synology01
export_pub 'Fractal'            fractal-audio
export_pub 'Digital Ocean'      digitalocean
export_pub 'Github Personal'    github-personal
export_pub 'ian@dads-gaming-pc' dads-gaming-pc
for f in home/private_dot_ssh/*.pub; do printf '%-48s ' "$f"; ssh-keygen -lf "$f" | awk '{print $2}'; done
```

Expected fingerprints (from the spec's verified constraints; stop if any differs):

| file | fingerprint |
|---|---|
| `rpi-basement-1.pub` | `SHA256:yeHusae3FowUytmC8lDDNkq4t7doyp929mOMRKc43Vw` |
| `tranquility.pub` | `SHA256:htVCGiGACy3++UOd0dE/LEQ97JDsF+YRtQI10HzFsE4` |
| `synology01.pub` | `SHA256:snswzxb06yeoXvaZtoEww4kO4fUxhbJcea2Ce7SXtVs` |
| `fractal-audio.pub` | `SHA256:91cfc5Pk0v9AwK8zDr8m37W3jd+xH/25WWJSI0r6jBg` |
| `digitalocean.pub` | `SHA256:QQ9JGRmbQGa4gQaTbxxeUBB5hcG+8+VCERUhVyU6hIA` |
| `github-personal.pub` | `SHA256:rSNe4sHOeBPZoi70lI7Ycbtb28fK7BbIEcPhw4HqGYQ` |
| `dads-gaming-pc.pub` | `SHA256:XSc3vPUj+r5GUwTfcnwYdlHKiYlCgUSyn+U/j7tCoNo` |

Also confirm no private material slipped in: `grep -l 'PRIVATE KEY' home/private_dot_ssh/*` must print nothing.

- [ ] **Step 4: Write `home/private_dot_1password/symlink_agent.sock.tmpl`**

```
{{ .chezmoi.homeDir }}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock
```

- [ ] **Step 5: Verify in a scratch destination (never the real home)**

```bash
root=$(git rev-parse --show-toplevel)
scratch=$(mktemp -d); : >"$scratch/c.toml"
cz() { chezmoi --source "$root" --destination "$scratch/home" --config "$scratch/c.toml" \
  --persistent-state "$scratch/state.boltdb" --exclude scripts "$@"; }
mkdir -p "$scratch/home"
umask 022
cz apply "$scratch/home/.ssh"
stat -c '%a %n' "$scratch/home/.ssh" "$scratch/home/.ssh/config" "$scratch/home/.ssh/"*.pub
cz ignored | grep -E '^\.(ssh|1password)' || true
touch "$scratch/home/.work_machine"
cz ignored | grep -E '^\.ssh' || echo 'MISSING: .ssh should be ignored on a work machine'
ssh -F "$scratch/home/.ssh/config" -G fractal-devenv | grep -E '^(identityfile|identitiesonly|hostname) '
ssh -F "$scratch/home/.ssh/config" -G imac | grep '^pubkeyauthentication'
rm -rf "$scratch"
```

Expected:
- `.ssh` 700, `config` 600, every `.pub` 644.
- First `ignored` call (no flag): lists `.1password` (this is Linux) but **not** `.ssh`.
- After `touch .work_machine`: `.ssh` is listed.
- `fractal-devenv`: `hostname 192.168.1.222`, `identityfile ~/.ssh/dads-gaming-pc.pub`, `identitiesonly yes`. (`ssh -G` expands `~` against the real home; that is fine.)
- `imac`: `pubkeyauthentication false` (OpenSSH 10 prints the boolean as `false`).

- [ ] **Step 6: Commit**

```bash
git add home/.chezmoiignore home/private_dot_ssh home/private_dot_1password
git commit -m 'Manage ~/.ssh/config and public keys with chezmoi

Personal machines only: .chezmoiignore skips ~/.ssh on work machines and the
cloud workstation. On macOS ~/.1password/agent.sock is symlinked to the
1Password group-container socket so every platform shares one agent path.

Co-Authored-By: Claude <noreply@anthropic.com>'
```

---

### Task 4: zsh agent wiring (`zshrc.d/1password.zsh`)

**Files:**
- Create: `home/dot_config/zsh/zshrc.d/1password.zsh`

**Interfaces:**
- Consumes: the `~/.1password/agent.sock` path from Task 3.
- Produces: on WSL, a live relay socket at `~/.1password/agent.sock`; on every platform, `SSH_AUTH_SOCK` pointed at it when appropriate.

- [ ] **Step 1: Write the module**

`home/dot_config/zsh/zshrc.d/1password.zsh`:

```zsh
# 1Password SSH agent
#
# ~/.1password/agent.sock is the one agent path on every platform: native Linux
# 1Password creates it, chezmoi symlinks it to the group-container socket on
# macOS, and on WSL the relay below serves it from the Windows named pipe.
# ~/.ssh/config points ssh at it only when the socket exists (Match exec); this
# file additionally exports SSH_AUTH_SOCK so ssh-add and other agent clients
# see 1Password too.

_op_sock="$HOME/.1password/agent.sock"

# True when an agent answers on $1. ssh-add -l exits 0 (keys) or 1 (no keys)
# after reaching an agent, 2 when it could not connect.
_op_sock_live() {
  [[ -S "$1" ]] || return 1
  SSH_AUTH_SOCK="$1" ssh-add -l >/dev/null 2>&1
  (( $? != 2 ))
}

# WSL: relay the Windows 1Password pipe onto the unix socket. Needs
# npiperelay.exe on the Windows side (winget install albertony.npiperelay) and
# socat/flock/setsid here. flock serialises shells started together (tmux
# restoring panes) so they cannot unlink each other's socket; the liveness check
# is repeated inside the lock. socat must not inherit the lock fd, or the lock
# would be held for the relay's whole life.
if [[ -r /proc/sys/kernel/osrelease && "$(</proc/sys/kernel/osrelease)" == *[Mm]icrosoft* ]] \
  && (( $+commands[npiperelay.exe] && $+commands[socat] && $+commands[flock] && $+commands[setsid] )); then
  mkdir -p -m 700 "$HOME/.1password"
  if ! _op_sock_live "$_op_sock"; then
    (
      flock -w 5 9 || exit 0
      _op_sock_live "$_op_sock" && exit 0
      rm -f "$_op_sock"
      setsid socat "UNIX-LISTEN:$_op_sock,fork" \
        "EXEC:npiperelay.exe -ei -s //./pipe/openssh-ssh-agent,nofork" </dev/null >/dev/null 2>&1 9>&- &
      for _i in {1..20}; do [[ -S "$_op_sock" ]] && break; sleep 0.05; done
    ) 9>"$HOME/.1password/.relay.lock"
  fi
fi

# Point agent clients at 1Password -- unless this is an SSH session that
# already carries a forwarded agent, which wins.
if [[ -S "$_op_sock" ]] && ! [[ -n "${SSH_CONNECTION:-}" && -S "${SSH_AUTH_SOCK:-}" ]]; then
  export SSH_AUTH_SOCK="$_op_sock"
fi

unset _op_sock _i
unfunction _op_sock_live
```

- [ ] **Step 2: Syntax-check and smoke-test without npiperelay**

```bash
zsh -n home/dot_config/zsh/zshrc.d/1password.zsh && echo 'syntax ok'
# npiperelay.exe is not installed on this box yet, so the relay branch must
# no-op and the shell must not export a socket that does not exist.
env -u SSH_AUTH_SOCK HOME="$(mktemp -d)" zsh -f -c \
  'zmodload zsh/parameter; source home/dot_config/zsh/zshrc.d/1password.zsh; echo "SSH_AUTH_SOCK=${SSH_AUTH_SOCK:-unset}"; whence -w _op_sock_live || true'
```

Expected: `syntax ok`; `SSH_AUTH_SOCK=unset`; `_op_sock_live: none` (helper cleaned up). Time a real shell start before and after (`time zsh -i -c exit`) and note the difference in the task report — it should be negligible off WSL and one `ssh-add -l` on WSL.

The live relay is verified by Ian in runbook step 3 (needs `npiperelay.exe` and the Windows service change).

- [ ] **Step 3: Commit**

```bash
git add home/dot_config/zsh/zshrc.d/1password.zsh
git commit -m 'Wire zsh to the 1Password SSH agent, with a WSL relay

Co-Authored-By: Claude <noreply@anthropic.com>'
```

---

### Task 5: `just doctor` checks

**Files:**
- Modify: `script/doctor` (new section before `# --- login shell`)

**Interfaces:**
- Consumes: the `Managed by chezmoi from ianchesal/dotfiles` header from Task 3; `~/.1password/agent.sock` from Tasks 3–4.
- Produces: nothing downstream.

- [ ] **Step 1: Add the section**

Insert directly above `# --- login shell ---...` in `script/doctor`:

```bash
# --- SSH via 1Password ----------------------------------------------------------
# ~/.ssh is chezmoi-managed on personal machines only; a managed config on a work
# or gcw box means .chezmoiignore did not catch it (flag missing at apply time).
section "SSH / 1Password"
ssh_excluded=0
{ [ -f "$HOME/.work_machine" ] || [ -d /etc/workstation-startup.d ]; } && ssh_excluded=1
if [ "$ssh_excluded" -eq 1 ]; then
  if grep -qF 'Managed by chezmoi from ianchesal/dotfiles' "$HOME/.ssh/config" 2>/dev/null; then
    warn "~/.ssh/config is chezmoi-managed on a work/gcw box -- restore the machine's own config"
  else
    ok "~/.ssh left to this machine (work/gcw)"
  fi
else
  if [ -S "$HOME/.1password/agent.sock" ]; then
    ok "1Password agent socket at ~/.1password/agent.sock"
  else
    note "no 1Password agent socket -- ssh falls back to SSH_AUTH_SOCK"
  fi
  if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
    if have npiperelay.exe; then ok "npiperelay.exe"; else warn "npiperelay.exe not on PATH -- 'winget install albertony.npiperelay'"; fi
    if have socat; then ok "socat"; else warn "socat not on PATH -- 'brew bundle install --file=$repo/brew/Brewfile'"; fi
  fi
  if have op; then ok "op $(op --version 2>/dev/null || echo '?')"; else note "op not installed -- just ssh::sync will skip"; fi
fi
```

- [ ] **Step 2: Verify**

Run: `just lint && just doctor; echo "exit=$?"`
Expected: lint clean; doctor shows the new section. On this WSL box today: `note` for the missing socket, `warn` for `npiperelay.exe` and `socat`, `ok op 2.40.0`. Doctor's exit code is unchanged by these (only `bad` fails it).

- [ ] **Step 3: Commit**

```bash
git add script/doctor
git commit -m 'Check the 1Password SSH setup in just doctor

Co-Authored-By: Claude <noreply@anthropic.com>'
```

---

### Task 6: Documentation

**Files:**
- Modify: `AGENTS.md`
- Create: `docs/tools/ssh.md`
- Modify: `docs/chezmoi-workflows.md`

**Interfaces:**
- Consumes: names from Tasks 1–5 (`just ssh::sync`, `script/ssh-config-sync`, `home/.chezmoiignore`, `home/private_dot_ssh/private_config`, `home/private_dot_1password/symlink_agent.sock.tmpl`, `zshrc.d/1password.zsh`).
- Produces: nothing downstream.

- [ ] **Step 1: AGENTS.md — Deployment section**

- Replace the bullet beginning `- Three chezmoi control files:` so it reads "Four chezmoi control files" and adds, after the `home/.chezmoiremove` clause: "`home/.chezmoiignore`, a template that skips `~/.ssh` on work machines (`~/.work_machine`) and the cloud workstation (`/etc/workstation-startup.d`), and skips `~/.1password` everywhere but macOS;". Keep the rest of the bullet.
- In the `- Prefixes in use:` bullet: change `symlink_` to "two entries, `symlink_nvim.tmpl` and `symlink_agent.sock.tmpl` (macOS 1Password agent socket)", and add "`private_` (0700 dirs / 0600 files: `private_dot_ssh`, `private_dot_ssh/private_config`, `private_dot_1password`, plus `create_private_settings.json`) — it applies per entry, so a file inside a `private_` dir still needs its own prefix".
- Change the bullet beginning `- Every config deploys on every platform.` to add at its end: "The one exception is `~/.ssh` (and the macOS-only `~/.1password` symlink), gated in `home/.chezmoiignore` — see SSH Configuration".

- [ ] **Step 2: AGENTS.md — commands and a new section**

In "Build/Test/Lint Commands", after the `just pi::update` line, add:

```markdown
- Pull `~/.ssh/config.d` host blocks from 1Password: `just ssh::sync` (also runs in the `update` fan-out)
```

Add a new section after "## Git Configuration":

```markdown
## SSH Configuration

- Private keys live **only** in 1Password (Private vault). Nothing in the repo or
  on disk holds a private key; `~/.ssh/*.pub` files are the public halves, used
  as `IdentityFile` so the agent knows which key to sign with
- `home/private_dot_ssh/private_config` → `~/.ssh/config` (0600). Public: LAN
  hosts (`192.168.1.x`), `github.com`, and a `Match exec "test -S
  ~/.1password/agent.sock"` block that sets `IdentityAgent`. Never make that
  unconditional: `IdentityAgent` overrides `SSH_AUTH_SOCK`, so a missing socket
  silently disables forwarded agents
- `Include config.d/*` is the first line. Host blocks that must not be published
  (public IPs, ports) are Secure Notes in 1Password tagged `ssh-config`; the
  title is the file name. `script/ssh-config-sync` (`just ssh::sync`, in the
  `update` fan-out) writes them with a `# managed by ssh-config-sync` header and
  only ever overwrites or prunes files carrying that header
- The sync skips (exit 0) without `op`, on a work machine or gcw, when `op whoami`
  fails or exceeds 60s, and **on macOS over SSH** — the 1Password app's auth
  prompt appears on the Mac's display and `op` blocks on it forever
- `~/.ssh` deploys to **personal machines only** (`home/.chezmoiignore`), the one
  exception to "every config deploys everywhere"
- One agent path everywhere, `~/.1password/agent.sock`: native on Linux, a
  chezmoi `symlink_` to the group-container socket on macOS, and on WSL a
  `socat` + `npiperelay.exe` relay started by `zshrc.d/1password.zsh` under
  `flock`. `npiperelay.exe` is Windows-side (`winget install albertony.npiperelay`)
  and the Windows *OpenSSH Authentication Agent* service must be disabled
- Every key-auth host pins its key (`IdentityFile <name>.pub` + `IdentitiesOnly
  yes`); password hosts set `PubkeyAuthentication no`. With nine keys in the
  agent an unpinned host hits `MaxAuthTries`
- Pull a public key out of 1Password with `op item get '<title>' --vault
  Private --fields 'public key'` — not `op read`, whose references reject the
  `@` in titles like `ian@tranquility`
- `known_hosts` and `authorized_keys` are machine-local; `private_dot_ssh` has no
  `exact_` prefix, so chezmoi leaves them and `config.d/` alone
```

- [ ] **Step 3: Create `docs/tools/ssh.md`**

```markdown
# SSH

Keys live in 1Password; config comes from this repo plus 1Password.

## Pieces

| What | Where | Managed by |
|---|---|---|
| Private keys | 1Password, Private vault, SSH Key items | 1Password only |
| `~/.ssh/config` (LAN hosts, GitHub, agent) | `home/private_dot_ssh/private_config` | chezmoi |
| Public keys `~/.ssh/*.pub` | `home/private_dot_ssh/*.pub` | chezmoi |
| `~/.ssh/config.d/<title>` (public-IP hosts) | Secure Notes tagged `ssh-config` | `just ssh::sync` |
| `~/.1password/agent.sock` | native (Linux), symlink (macOS), relay (WSL) | 1Password / chezmoi / `zshrc.d/1password.zsh` |
| `known_hosts`, `authorized_keys` | the machine | nobody |

Work machines and the cloud workstation get none of this (`home/.chezmoiignore`).

## Adding a host

- **LAN host:** add a block to `home/private_dot_ssh/private_config`; key auth
  pins `IdentityFile ~/.ssh/<name>.pub` + `IdentitiesOnly yes`, password auth
  sets `PubkeyAuthentication no`. `chezmoi apply ~/.ssh`.
- **Anything with a public IP:** create a Secure Note in Private, title = file
  name (letters, digits, `.`, `_`, `-`; must start with a letter or digit), tag
  `ssh-config`, body = the `Host` block. `just ssh::sync`.

## Adding a key

Generate or import it in the 1Password app (the CLI cannot import). Export the
public half into the repo:

    op item get '<item title>' --vault Private --fields 'public key' > home/private_dot_ssh/<name>.pub

## New machine

1. Install 1Password, enable *Settings → Developer → Use the SSH agent* (and CLI
   integration on macOS).
2. WSL only: `winget install albertony.npiperelay`; stop and disable the Windows
   *OpenSSH Authentication Agent* service; open a new shell.
3. `ssh-add -l` lists the 1Password keys.
4. `chezmoi apply`, then `just ssh::sync` (at the console on macOS — over SSH it
   skips, because the 1Password prompt would appear on the Mac's display).

## Troubleshooting

- `just ssh::sync` says not signed in: on WSL `eval "$(op signin)"`; on macOS
  unlock the app.
- `Permission denied (publickey)`: `ssh -G <host> | grep -E 'identity(file|agent)'`
  and `ssh-add -l`. No `identityagent` line means the socket is missing — on WSL,
  open a new shell to restart the relay, and check `just doctor`.
- `Too many authentication failures`: the host is not pinned; add
  `IdentityFile` + `IdentitiesOnly yes`.
```

- [ ] **Step 4: `docs/chezmoi-workflows.md`**

Under `## Bootstrapping a new machine`, append:

```markdown
SSH is a separate step after `chezmoi apply`, because the keys are in
1Password: enable the 1Password SSH agent, then run `just ssh::sync` (at the
console on macOS). See `docs/tools/ssh.md`.
```

Under `## Gotchas`, append a bullet in the file's existing bullet style:

```markdown
- `~/.ssh` is not deployed on a box that has `~/.work_machine` or
  `/etc/workstation-startup.d`. Touch the flag **before** the first apply on a
  work machine — chezmoi keeps no backup of the `~/.ssh/config` it would replace.
```

- [ ] **Step 5: Verify and commit**

Run: `git diff --stat && grep -n 'ssh::sync' AGENTS.md docs/tools/ssh.md docs/chezmoi-workflows.md`
Expected: each file mentions `ssh::sync`.

```bash
git add AGENTS.md docs/tools/ssh.md docs/chezmoi-workflows.md
git commit -m 'Document the 1Password SSH setup

Co-Authored-By: Claude <noreply@anthropic.com>'
```

---

### Task 7: Hand-off — draft the 1Password notes and stop

**Files:** none in the repo.

The rest is the spec's §4 runbook, which Ian runs. This task only prepares it.

- [ ] **Step 1: Draft the two Secure Note bodies for Ian to paste**

The bodies contain public IPs, so they are **printed to the terminal only** —
never written into this plan, the repo, a scratch file that gets committed, or
1Password (Ian creates the notes himself). Extract them from the live config,
switching each `IdentityFile` to the `.pub`:

```bash
print_hosts() {
  awk -v want="$1" '
    /^[[:space:]]*#?[Hh]ost[[:space:]]/ { keep = ($0 ~ want) }
    keep' ~/.ssh/config | sed -E 's#(IdentityFile[[:space:]]+~/\.ssh/[A-Za-z0-9._-]+)$#\1.pub#'
}
echo '===== note: fractal ====='; print_hosts '^Host fractal-(host2|xenforo)'
echo '===== note: chesal.net ====='; print_hosts '^Host chesal\.net'
```

Expected: `fractal` holds the `fractal-host2 fractal-web fractal-wiki
factal-axechange` and `fractal-xenforo` blocks, `chesal.net` its one block, all
with `IdentityFile ~/.ssh/<name>.pub` and `IdentitiesOnly yes`. Hand-check the
output (the awk stops a block at the next `Host` line; the commented
`#Host fractal-forum` block must not appear) and show it to Ian.

- [ ] **Step 2: Final checks and stop**

Run: `just lint && just test-scripts && git status --short`
Expected: clean lint, all tests `ok`, empty status. Then report to Ian and point at spec §4, steps 0 and 2–7. Do not apply to the real `~/.ssh`, delete keys, or touch Windows services.
