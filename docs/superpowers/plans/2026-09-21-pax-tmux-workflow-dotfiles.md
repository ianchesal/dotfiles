# pax Dispatcher tmux Workflow (dotfiles side) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure the tmux/workmux layout so each repo is a tmux session with a long-running pax lead in window 0, and add a dispatch action that hands a Claude planning worktree to that lead.

**Architecture:** Three deployed shell scripts under `home/dot_config/tmux/workmux/` (a repo opener, a dispatcher, and their menu wiring), plus a workmux config flip from `mode: session` to `mode: window`. The scripts carry the logic and take env-var seams so `script/tests/*.test.sh` can drive the source-state copies against fake `tmux`, `pi`, `workmux` and `git`. Nothing in workmux or pax changes in this plan.

**Tech Stack:** bash (portable to macOS's bash 3.2 — no `mapfile`, no associative arrays, no GNU-only `find -printf`), tmux `display-menu`/`popup`, fzf, chezmoi source state, `just` for lint/test.

**Spec:** `docs/superpowers/specs/2026-09-21-pax-tmux-workflow-design.md`

## Global Constraints

- Portable across macOS, Debian Linux and WSL2. **No GNU-only `find -printf`** — macOS ships BSD find. **No bash 4 features** in deployed scripts (macOS `/bin/bash` is 3.2).
- Shell: `set -euo pipefail`; must pass `shellcheck --severity=warning`.
- justfiles must pass `just --fmt --check`.
- Line length limit: 160 characters. Indentation: 2 spaces.
- Prefer single quotes unless interpolation is needed. snake_case for variables and functions.
- Deployed tmux helper scripts live in `home/dot_config/tmux/workmux/` with the `executable_` prefix; they deploy to `~/.config/tmux/workmux/` without it.
- Every script documents its test seams in a header comment block, matching `script/brew-tru
st`'s style.
- Tests live at `script/tests/<name>.test.sh`, are executable, and follow the existing harness idiom: `here`/`subject` resolution, `mktemp -d` work dir with an EXIT trap, fake binaries injected by env seam, a `check label expected actual` helper, a `failures` counter, and a nonzero exit when `failures > 0`.
- `just lint` and `just test-scripts` are what CI runs (`.github/workflows/ci.yml`). Both must pass.
- Markdown is **not** linted — do not add a markdown linter.
- chezmoi deploys these files; a tmux config edit is not live until `chezmoi apply`.

---

### Task 1: Flip workmux to window mode and drop the per-worktree pi window

The worktree layout currently spawns both a `claude` window and a `pi` window per worktree. Under the new model pax is per-repo, not per-worktree, so the `pi` window is wrong. `mode: session` must become `mode: window` so `workmux add` creates a window inside the repo's session, and `default_session` becomes dead config.

**Files:**
- Modify: `home/dot_config/workmux/config.yaml`

**Interfaces:**
- Consumes: nothing.
- Produces: `workmux add` creates a window in the current session rather than a new session. Task 3's dispatch script relies on the planning worktree being a window in the same session as the pax window.

- [ ] **Step 1: Read the current config**

Run: `cat home/dot_config/workmux/config.yaml`

Confirm it contains `mode: session`, `default_session: main`, and a `windows:` list with both a `claude` and a `pi` entry.

- [ ] **Step 2: Rewrite the config**

Replace the whole file with:

```yaml
# Each worktree opens as a window in the repo's own session. pax is per-repo and
# lives in window 0 of that session (see docs/superpowers/specs/
# 2026-09-21-pax-tmux-workflow-design.md), so a worktree window runs only the
# planning agent.
mode: window
# don't add dagent icons to tmux windows
# status_format: false
# enable nerd fonts, duh
nerdfont: true
# default agent
agent: claude

# auto-naming is automatic when agent is configured
# auto_name:
#   background: true # Always run in background when using --auto-name

# default window layout
windows:
  - name: claude
    panes:
      - command: claude --permission-mode auto
        focus: true
```

- [ ] **Step 3: Verify chezmoi sees exactly this change**

Run: `chezmoi diff ~/.config/workmux/config.yaml`

Expected: a diff removing `mode: session`, `default_session: main` and the `pi` window entry, and adding `mode: window`. No other paths appear.

- [ ] **Step 4: Apply and confirm workmux reports window mode**

Run:
```bash
chezmoi apply --error-on-conflict ~/.config/workmux/config.yaml
workmux list --json
```

Expected: the entry for the current repo reports `"mode":"window"`.

- [ ] **Step 5: Commit**

```bash
git add home/dot_config/workmux/config.yaml
git commit -m "Move workmux to window mode for per-repo pax sessions"
```

---

### Task 2: The repo opener

A repo is opened as a tmux session named for the repo basename, with window 0 running pax at the repo root under a stable pi session id and a stable Computer port. Ports come from a persisted registry rather than a hash, because hashing ~22 repos into a small range collides often (birthday problem) while a registry cannot collide at all.

**Files:**
- Create: `home/dot_config/tmux/workmux/executable_pax-open-repo.sh`
- Create: `script/tests/pax-open-repo.test.sh`

**Interfaces:**
- Consumes: nothing.
- Produces: a tmux session named `<repo-basename>` whose window 0 is named `pax`, running `<PAX_BIN> --session-id pax-<repo>` with `PAX_COMPUTER_PORT` set, cwd = repo root. Task 3 relies on the window being named exactly `pax`, and Task 4 invokes this script.
- Seams (env vars): `SRC_ROOT` (default `$HOME/src`), `PORT_REGISTRY` (default `${XDG_STATE_HOME:-$HOME/.local/state}/pax/ports`), `TMUX_BIN` (default `tmux`), `PAX_BIN` (default `pi`), `PAX_LIST_ONLY` (when non-empty, print `<name> <path>` per repo and exit 0).

- [ ] **Step 1: Write the failing test**

Create `script/tests/pax-open-repo.test.sh`:

```bash
#!/usr/bin/env bash
#
# Tests for home/dot_config/tmux/workmux/executable_pax-open-repo.sh. Drives the
# script against a fake tmux and a scratch ~/src so no real session is created.
#
# Run: script/tests/pax-open-repo.test.sh

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
subject=$here/../../home/dot_config/tmux/workmux/executable_pax-open-repo.sh

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

# A fake tmux that records its argv one call per line and reports "no session".
cat >"$work/tmux" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >>"$TMUX_CALLS"
[ "${1:-}" = "has-session" ] && exit 1
exit 0
FAKE
chmod +x "$work/tmux"

# A fake tmux that reports the session already exists.
cat >"$work/tmux-existing" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >>"$TMUX_CALLS"
exit 0
FAKE
chmod +x "$work/tmux-existing"

src=$work/src
mkdir -p "$src/toplevel/.git" "$src/org/nested/.git" "$src/org/nested__worktrees/wt/.git"

run() {
  : >"$work/calls"
  TMUX_CALLS=$work/calls SRC_ROOT=$src TMUX_BIN=${1:-$work/tmux} \
    PORT_REGISTRY=$work/ports PAX_BIN=paxfake \
    "$subject" "${@:2}" >"$work/out" 2>"$work/err"
}

echo "pax-open-repo"

# --- enumeration finds both depths and excludes worktree storage -------------
PAX_LIST_ONLY=1 SRC_ROOT=$src PORT_REGISTRY=$work/ports "$subject" >"$work/list" 2>&1
check "lists both repo depths" "nested toplevel" "$(awk '{print $1}' "$work/list" | sort | tr '\n' ' ' | sed 's/ $//')"
check "excludes __worktrees" "0" "$(grep -c '__worktrees' "$work/list" || true)"

# --- port allocation is stable and collision-free ----------------------------
rm -f "$work/ports"
run "$work/tmux" toplevel
first=$(awk '$1 == "toplevel" { print $2 }' "$work/ports")
check "first repo gets the base port" "8800" "$first"
run "$work/tmux" nested
check "second repo gets the next port" "8801" "$(awk '$1 == "nested" { print $2 }' "$work/ports")"
run "$work/tmux" toplevel
check "re-opening reuses the same port" "8800" "$(awk '$1 == "toplevel" { print $2 }' "$work/ports")"

# --- a new session is created with pax in window 0 ---------------------------
rm -f "$work/ports"
run "$work/tmux" toplevel
check "creates a detached session named for the repo" "1" \
  "$(grep -c -- "new-session -d -s toplevel -c $src/toplevel -n pax" "$work/calls" || true)"
check "launches pax with a stable session id" "1" \
  "$(grep -c -- '--session-id pax-toplevel' "$work/calls" || true)"
check "pins the computer port" "1" "$(grep -c 'PAX_COMPUTER_PORT=8800' "$work/calls" || true)"

# --- an existing session is attached, not recreated --------------------------
run "$work/tmux-existing" toplevel
check "does not recreate an existing session" "0" "$(grep -c -- 'new-session' "$work/calls" || true)"
check "switches to the existing session" "1" "$(grep -c -- 'switch-client -t =toplevel' "$work/calls" || true)"

# --- an unknown repo is an error, not a silent no-op -------------------------
if run "$work/tmux" nosuchrepo; then
  check "unknown repo fails" "nonzero exit" "exit 0"
else
  check "unknown repo fails" "nonzero exit" "nonzero exit"
fi

if [ "$failures" -gt 0 ]; then
  printf '  %d failure(s)\n' "$failures"
  exit 1
fi
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `chmod +x script/tests/pax-open-repo.test.sh && script/tests/pax-open-repo.test.sh`

Expected: FAIL — the subject script does not exist yet, so the first invocation errors with "No such file or directory".

- [ ] **Step 3: Write the script**

Create `home/dot_config/tmux/workmux/executable_pax-open-repo.sh`:

```bash
#!/usr/bin/env bash
#
# Open a repo as its own tmux session with a long-running pax lead in window 0.
#
# The session is named for the repo's basename; window 0 is named "pax" and runs
# pi under a stable --session-id so the window is cheap to kill and relaunch --
# the multi-hour dispatcher context lives in pi's session store, not the pane.
#
# Computer ports come from a persisted registry rather than a hash of the repo
# name: hashing ~20 repos into any range small enough to be memorable collides
# far more often than intuition suggests, and a registry cannot collide at all.
#
# Seams for script/tests/pax-open-repo.test.sh:
#   SRC_ROOT      -- where checkouts live (default: $HOME/src)
#   PORT_REGISTRY -- repo->port map (default: $XDG_STATE_HOME/pax/ports)
#   TMUX_BIN      -- tmux executable (default: tmux)
#   PAX_BIN       -- pax/pi executable (default: pi)
#   PAX_LIST_ONLY -- when non-empty, print "<name> <path>" per repo and exit

set -euo pipefail

src_root=${SRC_ROOT:-$HOME/src}
tmux_bin=${TMUX_BIN:-tmux}
pax_bin=${PAX_BIN:-pi}
registry=${PORT_REGISTRY:-${XDG_STATE_HOME:-$HOME/.local/state}/pax/ports}
port_base=8800
port_span=1000

# BSD find has no -printf, so strip the /.git suffix with sed instead.
list_repos() {
  find "$src_root" -maxdepth 3 -name .git -not -path '*__worktrees*' 2>/dev/null |
    sed 's|/\.git$||' | sort
}

path_for() {
  local name=$1 path
  while IFS= read -r path; do
    [ "$(basename "$path")" = "$name" ] && { printf '%s\n' "$path"; return 0; }
  done <<EOF
$(list_repos)
EOF
  return 1
}

port_for() {
  local name=$1 port
  mkdir -p "$(dirname "$registry")"
  [ -f "$registry" ] || : >"$registry"
  port=$(awk -v n="$name" '$1 == n { print $2; exit }' "$registry")
  if [ -n "$port" ]; then
    printf '%s\n' "$port"
    return 0
  fi
  port=$port_base
  while awk -v p="$port" '$2 == p { found = 1 } END { exit !found }' "$registry"; do
    port=$((port + 1))
    if [ "$port" -ge $((port_base + port_span)) ]; then
      echo "pax-open-repo: port registry exhausted at $registry" >&2
      return 1
    fi
  done
  printf '%s %s\n' "$name" "$port" >>"$registry"
  printf '%s\n' "$port"
}

focus_session() {
  local name=$1
  "$tmux_bin" switch-client -t "=$name" 2>/dev/null ||
    "$tmux_bin" attach-session -t "=$name"
}

open_repo() {
  local name=$1 path port
  path=$(path_for "$name") || {
    echo "pax-open-repo: no repo named '$name' under $src_root" >&2
    return 1
  }
  if "$tmux_bin" has-session -t "=$name" 2>/dev/null; then
    focus_session "$name"
    return 0
  fi
  port=$(port_for "$name") || return 1
  "$tmux_bin" new-session -d -s "$name" -c "$path" -n pax \
    "PAX_COMPUTER_PORT=$port $pax_bin --session-id pax-$name"
  focus_session "$name"
}

pick_repo() {
  # FZF_DEFAULT_OPTS sets --tmux, which makes fzf spawn its own nested tmux
  # popup for its UI. Since this script already runs inside a popup, that
  # nesting breaks (fzf exits immediately with no selection). Strip --tmux
  # for this invocation so fzf renders inline in the popup we already have.
  local opts
  opts=$(echo "${FZF_DEFAULT_OPTS:-}" | sed -E 's/--tmux(=[^ ]+)?( [a-z]+)?//')
  list_repos | sed 's|.*/||' | FZF_DEFAULT_OPTS="$opts" fzf
}

if [ -n "${PAX_LIST_ONLY:-}" ]; then
  list_repos | while IFS= read -r path; do
    printf '%s %s\n' "$(basename "$path")" "$path"
  done
  exit 0
fi

name=${1:-}
[ -n "$name" ] || name=$(pick_repo)
[ -n "$name" ] || exit 0

open_repo "$name" || {
  # Only pause when there is a tty to pause for: the popup needs the message to
  # stay on screen, but script/tests/pax-open-repo.test.sh would hang on it.
  if [ -t 0 ]; then
    echo
    echo "pax-open-repo failed. Press any key to close."
    read -r -n 1 -s
  fi
  exit 1
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `script/tests/pax-open-repo.test.sh`

Expected: every line prints `ok`, exit 0.

- [ ] **Step 5: Lint**

Run: `shellcheck --severity=warning home/dot_config/tmux/workmux/executable_pax-open-repo.sh script/tests/pax-open-repo.test.sh`

Expected: no output, exit 0.

- [ ] **Step 6: Commit**

```bash
git add home/dot_config/tmux/workmux/executable_pax-open-repo.sh script/tests/pax-open-repo.test.sh
git commit -m "Add pax repo-session opener"
```

---

### Task 3: The dispatch action

Run from a Claude planning worktree's window, this hands that worktree to the repo's pax lead. It finds the prompt file the planning branch added, composes an instruction naming the worktree as `workingDir`, sends it to the lead via `workmux send`, and switches to the pax window.

The instruction must name `workingDir` explicitly. If the lead delegates without one, pax provisions its own worktree off `origin/main`, outside workmux's view — the spec's open question.

**Files:**
- Create: `home/dot_config/tmux/workmux/executable_pax-dispatch.sh`
- Create: `script/tests/pax-dispatch.test.sh`

**Interfaces:**
- Consumes: Task 2's session layout — window 0 named `pax` in a session named for the repo.
- Produces: a `workmux send <repo> <instruction>` call. Task 4 invokes this script.
- Seams (env vars): `WORKMUX_BIN` (default `workmux`), `TMUX_BIN` (default `tmux`), `PAX_DISPATCH_DRY_RUN` (when non-empty, print the instruction to stdout and skip both the send and the window switch).

- [ ] **Step 1: Write the failing test**

Create `script/tests/pax-dispatch.test.sh`:

```bash
#!/usr/bin/env bash
#
# Tests for home/dot_config/tmux/workmux/executable_pax-dispatch.sh. Builds a
# real git repo with a real worktree in a scratch dir, so prompt discovery is
# exercised against actual git plumbing, and fakes only workmux and tmux.
#
# Run: script/tests/pax-dispatch.test.sh

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
subject=$here/../../home/dot_config/tmux/workmux/executable_pax-dispatch.sh

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

# The instruction is multi-line; flatten each call onto one line so `grep -c`
# counts calls rather than matching lines.
cat >"$work/workmux" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" | tr '\n' ' ' >>"$WORKMUX_CALLS"
echo >>"$WORKMUX_CALLS"
exit 0
FAKE
chmod +x "$work/workmux"

cat >"$work/tmux" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >>"$TMUX_CALLS"
exit 0
FAKE
chmod +x "$work/tmux"

# A repo named "demo" on main, with a planning worktree that adds one prompt.
repo=$work/demo
git init -q -b main "$repo"
git -C "$repo" config user.email t@example.com
git -C "$repo" config user.name Test
mkdir -p "$repo/docs/superpowers/prompts"
echo base >"$repo/README.md"
git -C "$repo" add -A
git -C "$repo" commit -q -m base

wt=$work/demo__worktrees/planning
git -C "$repo" worktree add -q -b planning "$wt" >/dev/null 2>&1
mkdir -p "$wt/docs/superpowers/prompts"
echo 'do the thing' >"$wt/docs/superpowers/prompts/2026-09-21-thing-prompt.md"
git -C "$wt" add -A
git -C "$wt" commit -q -m 'Add prompt'

run() {
  : >"$work/wm-calls"
  : >"$work/tmux-calls"
  ( cd "${1:-$wt}" && WORKMUX_CALLS=$work/wm-calls TMUX_CALLS=$work/tmux-calls \
      WORKMUX_BIN=$work/workmux TMUX_BIN=$work/tmux "$subject" ) \
    >"$work/out" 2>"$work/err"
}

echo "pax-dispatch"

# --- the branch-added prompt is discovered -----------------------------------
run "$wt"
check "sends to the repo's main handle" "1" "$(grep -c '^send demo ' "$work/wm-calls" || true)"
check "names the prompt by absolute path" "1" \
  "$(grep -c "@$wt/docs/superpowers/prompts/2026-09-21-thing-prompt.md" "$work/wm-calls" || true)"
check "does not use a worktree-relative prompt path" "0" \
  "$(grep -c '@docs/superpowers' "$work/wm-calls" || true)"
check "names the worktree as workingDir" "1" "$(grep -c "workingDir=\"$wt\"" "$work/wm-calls" || true)"
check "names the branch" "1" "$(grep -c 'branch planning' "$work/wm-calls" || true)"
check "switches to the pax window" "1" "$(grep -c 'select-window -t :pax' "$work/tmux-calls" || true)"

# --- a worktree that added no prompt is an error -----------------------------
wt2=$work/demo__worktrees/empty
git -C "$repo" worktree add -q -b empty "$wt2" >/dev/null 2>&1
if run "$wt2"; then
  check "no prompt file fails" "nonzero exit" "exit 0"
else
  check "no prompt file fails" "nonzero exit" "nonzero exit"
fi
check "no prompt file sends nothing" "0" "$(wc -l <"$work/wm-calls" | tr -d ' ')"

# --- two prompts is ambiguous and must not guess -----------------------------
wt3=$work/demo__worktrees/two
git -C "$repo" worktree add -q -b two "$wt3" >/dev/null 2>&1
mkdir -p "$wt3/docs/superpowers/prompts"
echo a >"$wt3/docs/superpowers/prompts/2026-09-21-a-prompt.md"
echo b >"$wt3/docs/superpowers/prompts/2026-09-21-b-prompt.md"
git -C "$wt3" add -A
git -C "$wt3" commit -q -m 'Add two prompts'
if run "$wt3"; then
  check "ambiguous prompts fail" "nonzero exit" "exit 0"
else
  check "ambiguous prompts fail" "nonzero exit" "nonzero exit"
fi
check "ambiguous prompts name both" "1" "$(grep -c 'a-prompt.md' "$work/err" || true)"

# --- a gitignored prompt dir gets its own diagnosis --------------------------
wt4=$work/demo__worktrees/ignored
git -C "$repo" worktree add -q -b ignored "$wt4" >/dev/null 2>&1
echo 'docs/superpowers/' >"$wt4/.gitignore"
mkdir -p "$wt4/docs/superpowers/prompts"
echo x >"$wt4/docs/superpowers/prompts/2026-09-21-x-prompt.md"
git -C "$wt4" add .gitignore
git -C "$wt4" commit -q -m 'Ignore superpowers docs'
if run "$wt4"; then
  check "gitignored prompt dir fails" "nonzero exit" "exit 0"
else
  check "gitignored prompt dir fails" "nonzero exit" "nonzero exit"
fi
check "gitignored prompt dir says so" "1" "$(grep -c 'gitignored' "$work/err" || true)"

# --- running from the main checkout is refused -------------------------------
if run "$repo"; then
  check "dispatch from main checkout fails" "nonzero exit" "exit 0"
else
  check "dispatch from main checkout fails" "nonzero exit" "nonzero exit"
fi

if [ "$failures" -gt 0 ]; then
  printf '  %d failure(s)\n' "$failures"
  exit 1
fi
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `chmod +x script/tests/pax-dispatch.test.sh && script/tests/pax-dispatch.test.sh`

Expected: FAIL — the subject script does not exist.

- [ ] **Step 3: Write the script**

Create `home/dot_config/tmux/workmux/executable_pax-dispatch.sh`:

```bash
#!/usr/bin/env bash
#
# Hand the current Claude planning worktree to this repo's pax lead.
#
# pax baselines its own lane worktrees off origin/main, so the only way the
# planning artifacts (spec, plan, prompt) reach the implementation is to point a
# lane at THIS worktree via workingDir. Implementation commits then land on the
# planning branch and everything reaches review in one PR -- protected main is
# never merged into. See docs/superpowers/specs/
# 2026-09-21-pax-tmux-workflow-design.md.
#
# The instruction below names workingDir explicitly on purpose: a delegation
# without one makes pax provision a worktree off origin/main that workmux cannot
# see.
#
# Seams for script/tests/pax-dispatch.test.sh:
#   WORKMUX_BIN          -- workmux executable (default: workmux)
#   TMUX_BIN             -- tmux executable (default: tmux)
#   PAX_DISPATCH_DRY_RUN -- when non-empty, print the instruction and stop

set -euo pipefail

workmux_bin=${WORKMUX_BIN:-workmux}
tmux_bin=${TMUX_BIN:-tmux}
prompt_dir=docs/superpowers/prompts

fail() {
  echo "pax-dispatch: $*" >&2
  exit 1
}

git rev-parse --git-dir >/dev/null 2>&1 || fail "not a git repository"

worktree=$(git rev-parse --show-toplevel)
branch=$(git rev-parse --abbrev-ref HEAD)

# The first entry of `git worktree list` is always the main working tree; its
# basename is the repo name, which is also workmux's handle for the is_main
# entry and therefore the target of `workmux send`.
main_tree=$(git worktree list --porcelain | awk '/^worktree /{print $2; exit}')
repo=$(basename "$main_tree")

[ "$worktree" != "$main_tree" ] ||
  fail "this is the main checkout, not a planning worktree -- dispatch from the worktree window"

base=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null || echo origin/main)
git rev-parse --verify --quiet "$base" >/dev/null 2>&1 || base=main

prompts=$(git diff --name-only "$base...HEAD" -- "$prompt_dir" || true)
count=$(printf '%s' "$prompts" | grep -c . || true)

if [ "$count" -eq 0 ]; then
  # A gitignored prompt dir looks identical to a missing prompt from here, and
  # is the more confusing failure -- the file is right there on disk. The spec's
  # precondition: pax reads the prompt from the branch, so it must be committed.
  if git check-ignore -q "$prompt_dir" 2>/dev/null; then
    fail "$prompt_dir is gitignored in this repo, so the prompt can never reach the branch -- un-ignore it before dispatching"
  fi
  fail "branch '$branch' adds no file under $prompt_dir -- write the pax prompt first"
fi
if [ "$count" -gt 1 ]; then
  fail "branch '$branch' adds $count files under $prompt_dir, expected exactly one:
$prompts"
fi

# The @ path must be ABSOLUTE. `git diff --name-only` yields a path relative to
# the worktree, but the lead's cwd is the repo root on main -- where the prompt
# does not exist, because it is committed on the planning branch. A relative
# path silently fails to resolve there.
instruction="Execute the plan in @$worktree/$prompts.
Delegate it with workingDir=\"$worktree\" so the work happens in that existing worktree on branch $branch, where the spec, plan and prompt are already committed.
Do not provision a new worktree: implementation commits must land on branch $branch so everything reaches review in one PR."

if [ -n "${PAX_DISPATCH_DRY_RUN:-}" ]; then
  printf '%s\n' "$instruction"
  exit 0
fi

"$workmux_bin" send "$repo" "$instruction" || fail "workmux send to '$repo' failed"
"$tmux_bin" select-window -t :pax || true
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `script/tests/pax-dispatch.test.sh`

Expected: every line prints `ok`, exit 0.

- [ ] **Step 5: Lint**

Run: `shellcheck --severity=warning home/dot_config/tmux/workmux/executable_pax-dispatch.sh script/tests/pax-dispatch.test.sh`

Expected: no output, exit 0.

- [ ] **Step 6: Commit**

```bash
git add home/dot_config/tmux/workmux/executable_pax-dispatch.sh script/tests/pax-dispatch.test.sh
git commit -m "Add pax dispatch action for handing a planning worktree to the lead"
```

---

### Task 4: Wire both actions into the prefix+w menu

**Files:**
- Modify: `home/dot_config/tmux/tmux.conf:147-156` (the `bind w display-menu` block)

**Interfaces:**
- Consumes: Tasks 2 and 3's scripts, deployed at `~/.config/tmux/workmux/pax-open-repo.sh` and `~/.config/tmux/workmux/pax-dispatch.sh` (chezmoi strips the `executable_` prefix).
- Produces: nothing downstream.

- [ ] **Step 1: Add the two entries**

In `home/dot_config/tmux/tmux.conf`, inside the `bind w display-menu` block, insert these two lines immediately after the `-T "workmux"` line and before the existing `"add" a` line:

```
    "open repo" R "popup -d '#{pane_current_path}' -w 80% -h 40% -x C -y C -E '~/.config/tmux/workmux/pax-open-repo.sh'" \
    "dispatch to pax" D "popup -d '#{pane_current_path}' -w 80% -h 30% -x C -y C -E '~/.config/tmux/workmux/pax-dispatch.sh'" \
```

`R` and `D` are chosen because the block already uses `a`, `b`, `p`, `o`, `r`, `c`, `d`, `s` and `q`; tmux menu keys are case-sensitive, so the uppercase pair does not collide with `r` (remove) or `d` (dashboard).

- [ ] **Step 2: Verify the justfile and shell lint still pass**

Run: `just lint`

Expected: exit 0. (`tmux.conf` is not shellchecked, but this confirms nothing else regressed.)

- [ ] **Step 3: Apply and confirm tmux parses the menu**

Run:
```bash
chezmoi apply --error-on-conflict ~/.config/tmux
tmux source-file ~/.config/tmux/tmux.conf
tmux list-keys -T prefix | grep 'display-menu -T workmux'
```

Expected: one line, containing both `open repo R` and `dispatch to pax D`. A parse error in the menu would make `source-file` fail loudly instead.

- [ ] **Step 4: Run the full test suite**

Run: `just test-scripts`

Expected: `pax-open-repo` and `pax-dispatch` both appear with all `ok` lines, and every pre-existing test still passes.

- [ ] **Step 5: Commit**

```bash
git add home/dot_config/tmux/tmux.conf
git commit -m "Add open-repo and dispatch entries to the workmux tmux menu"
```

---

## Manual verification

The plan's tests cover logic against fakes. These steps confirm the real thing, and cannot be automated because they need a live tmux and a live pax:

- [ ] `prefix+w → open repo`, pick a repo. A session named for the repo appears with window 0 named `pax` running pi. `prefix+s` shows it.
- [ ] From that session, `prefix+w → add w/prompt`. A **window** appears in the same session (not a new session) running Claude.
- [ ] Have Claude commit a file under `docs/superpowers/prompts/` on that branch.
- [ ] `prefix+w → dispatch to pax`. The lead receives the instruction and the view switches to the `pax` window.
- [ ] Confirm the known-wrong status from the spec: `workmux list --json` reports the lead `done` while a sidekick is still working. This is what the pax PR fixes; it is expected here.

## Known-wrong until the pax PR

Per the spec's status-bridge section, the lead reports `done` while sidekicks work, and the planning worktree's own window carries no agent status. Do not work around either by scraping pax's Computer server — the fix is `suba:activity` emission plus `$TMUX_PANE`-targeted `workmux set-window-status`, both pax-side, in a separate plan.
