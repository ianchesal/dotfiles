# Standalone Bash Fallback Configuration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give Ian a standalone, plugin-free bash configuration (chezmoi-managed) that feels comfortable the way his zsh setup does, for use on root shells, embedded/minimal Debian boxes, and remote servers he doesn't own.

**Architecture:** A thin `~/.bashrc` loader sources `~/.config/bash/bashrc.sh`, which in turn sources numbered modules in `~/.config/bash/bashrc.d/*.bash` (history, shell options, env/Homebrew, aliases, prompt, completion, fzf). `~/.bash_profile` sources `~/.bashrc` so login shells (macOS Terminal.app, SSH) pick it up. `~/.inputrc` carries readline tuning independent of bash itself. Every optional integration (oh-my-posh, fzf, bash-completion, Homebrew) is probed with a guard clause and no-ops silently when absent.

**Tech Stack:** POSIX-adjacent bash 3.2+ (no associative arrays, no `mapfile`), readline (`~/.inputrc`), optionally oh-my-posh / fzf / bash-completion when present on `PATH`.

**Spec:** `docs/superpowers/specs/2026-09-13-standalone-bash-config-design.md`

## Global Constraints

- bash 3.2+ compatible: no associative arrays, no `mapfile`, no `${var,,}`; guard any bash-4+-only feature (e.g. `globstar`) behind `(( BASH_VERSINFO[0] >= 4 ))`.
- No plugin manager, no network calls at shell start. Every external dependency is optional, probed via `command -v` / `[[ -f ]]`, and silent when absent.
- Must work unmodified on both macOS and Debian (guard OS-specific behavior via `$OSTYPE`, not separate files).
- Feel-only scope: history, prompt, a handful of safety aliases, readline tuning, vi keybindings. No git aliases, no fzf-git, no kubectl/docker/terraform helpers.
- Every new shell file must pass `shellcheck --severity=warning` (repo-wide requirement enforced by `just lint`).
- Chezmoi naming: `dot_` prefix at every path level; source state root is `home/` (`.chezmoiroot`).

---

## Task 1: Loader chain — `.bashrc`, `.bash_profile`, `bashrc.sh`

**Files:**
- Create: `home/dot_bashrc`
- Create: `home/dot_bash_profile`
- Create: `home/dot_config/bash/dot_bashrc.sh`
- Create: `home/dot_config/bash/bashrc.d/` (empty dir placeholder not needed — Task 2 populates it)

**Interfaces:**
- Produces: the sourcing chain `~/.bashrc` → `~/.config/bash/bashrc.sh` → `~/.config/bash/bashrc.d/*.bash` (skips names starting with `~`), which every later task's module file relies on being sourced automatically.

- [ ] **Step 1: Write `home/dot_bashrc`**

```bash
#!/usr/bin/env bash
# Thin loader: the real configuration lives under XDG-style
# ~/.config/bash so it stays consistent with the rest of this repo's
# tool configs (see zsh's ZDOTDIR indirection for the same idea).

[[ -f "$HOME/.config/bash/bashrc.sh" ]] && source "$HOME/.config/bash/bashrc.sh"
```

- [ ] **Step 2: Write `home/dot_bash_profile`**

```bash
#!/usr/bin/env bash
# bash only auto-sources ~/.bashrc for non-login interactive shells.
# macOS Terminal.app and SSH sessions start login shells, which read
# this file instead -- without this shim the whole config never runs
# on exactly the platforms it's meant for.

[[ -f "$HOME/.bashrc" ]] && source "$HOME/.bashrc"
```

- [ ] **Step 3: Write `home/dot_config/bash/dot_bashrc.sh`**

```bash
#!/usr/bin/env bash
# Sources every module in bashrc.d/ in filename order. Numeric
# prefixes control load order (env before prompt, etc.). Files
# starting with '~' are skipped, matching the zsh loader's convention
# for disabling a module without deleting it.

bashrc_dir="${HOME}/.config/bash/bashrc.d"

if [[ -d "$bashrc_dir" ]]; then
  for rc in "$bashrc_dir"/*.bash; do
    [[ -e "$rc" ]] || continue
    case "$(basename "$rc")" in
      '~'*) continue ;;
    esac
    source "$rc"
  done
fi

unset bashrc_dir rc
```

- [ ] **Step 4: Verify the chain loads without error**

Run: `bash -c 'source home/dot_bashrc; echo LOADED'` from the repo root.
Expected: prints `LOADED` with no errors (the `bashrc.d` glob loop is a no-op since the directory doesn't exist yet — `[[ -d ]]` guards that).

- [ ] **Step 5: Shellcheck all three files**

Run: `shellcheck --severity=warning home/dot_bashrc home/dot_bash_profile home/dot_config/bash/dot_bashrc.sh`
Expected: no warnings.

- [ ] **Step 6: Wire these files into the repo's shellcheck lint**

`just lint` (`justfile:53-62`) hardcodes its shellcheck file list rather than
globbing, so these new files are invisible to it until added explicitly. Edit
the `lint` recipe in `justfile`:

```
shellcheck --severity=warning \
  script/asdf-prune script/gem-cleanup script/nvim-commit script/doctor \
  script/brew-trust \
  script/verify-chezmoi-assumptions.sh home/run_once_*.sh \
  script/tests/*.test.sh bootstrap/*.sh \
  home/dot_bashrc home/dot_bash_profile home/dot_config/bash/dot_bashrc.sh
```

(Tasks 2-9 add their own `bashrc.d/*.bash` files — Task 10 extends this same
line to `home/dot_config/bash/bashrc.d/*.bash` once they all exist, since the
glob would otherwise fail on files that don't exist yet at this point in the
plan.)

- [ ] **Step 7: Verify `just --fmt --check` still passes**

Run: `just --fmt --check --justfile "$PWD/justfile"`
Expected: passes (no formatting drift from the edit).

- [ ] **Step 8: Commit**

```bash
git add home/dot_bashrc home/dot_bash_profile home/dot_config/bash/dot_bashrc.sh justfile
git commit -m "$(cat <<'EOF'
Add bash loader chain for standalone fallback config

Sets up ~/.bashrc -> ~/.config/bash/bashrc.sh -> bashrc.d/*.bash
sourcing, plus a ~/.bash_profile shim so login shells pick it up.
Wires the new files into `just lint`'s shellcheck pass.

Co-Authored-By: Claude <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_018ZBw71gisQk8Lv2f97XfGK
EOF
)"
```

---

## Task 2: History module

**Files:**
- Create: `home/dot_config/bash/bashrc.d/01-history.bash`

**Interfaces:**
- Consumes: nothing (first module loaded).
- Produces: `HISTSIZE`, `HISTFILESIZE`, `HISTCONTROL`, `HISTTIMEFORMAT` exported for the rest of the session; `PROMPT_COMMAND` seeded with the shared-history append (later modules that also extend `PROMPT_COMMAND`, i.e. the prompt module in Task 6, must append to it rather than overwrite it).

- [ ] **Step 1: Write `home/dot_config/bash/bashrc.d/01-history.bash`**

```bash
# History: large, deduped, shared across concurrent sessions.
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoredups:erasedups
HISTTIMEFORMAT='%F %T  '
shopt -s histappend

# Append this session's new lines, clear this shell's history buffer,
# then re-read the file -- so a command typed in one terminal shows up
# in another's history immediately, the closest bash gets to zsh's
# SHARE_HISTORY.
bash_history_sync() {
  history -a
  history -c
  history -r
}
PROMPT_COMMAND="bash_history_sync${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
```

- [ ] **Step 2: Verify it loads and behaves**

Run: `bash -c 'source home/dot_config/bash/bashrc.d/01-history.bash; echo "$HISTCONTROL / $PROMPT_COMMAND"'`
Expected: prints `ignoredups:erasedups / bash_history_sync` with no errors.

- [ ] **Step 3: Shellcheck**

Run: `shellcheck --severity=warning home/dot_config/bash/bashrc.d/01-history.bash`
Expected: no warnings.

- [ ] **Step 4: Commit**

```bash
git add home/dot_config/bash/bashrc.d/01-history.bash
git commit -m "$(cat <<'EOF'
Add bash history module with cross-session sharing

Co-Authored-By: Claude <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_018ZBw71gisQk8Lv2f97XfGK
EOF
)"
```

---

## Task 3: Shell options and vi mode

**Files:**
- Create: `home/dot_config/bash/bashrc.d/02-shopts.bash`

**Interfaces:**
- Consumes: nothing.
- Produces: `set -o vi` active for the rest of the session (later modules must not assume emacs-style `bind` key names, though none of the remaining tasks bind readline keys directly — that's confined to `~/.inputrc` in Task 9, which works under either editing mode).

- [ ] **Step 1: Write `home/dot_config/bash/bashrc.d/02-shopts.bash`**

```bash
# Sane interactive shell options, bash 3.2 safe.
shopt -s checkwinsize
shopt -s extglob

# globstar (**/) is bash 4+ only; guard for macOS's stock bash 3.2.
if (( BASH_VERSINFO[0] >= 4 )); then
  shopt -s globstar
fi

# Match the vi keybindings used in the zsh setup.
set -o vi
```

- [ ] **Step 2: Verify it loads under both simulated bash versions**

Run: `bash -c 'source home/dot_config/bash/bashrc.d/02-shopts.bash; shopt checkwinsize extglob; set -o | grep vi'`
Expected: `checkwinsize` and `extglob` both print `on`; the `vi` line in `set -o` output shows `on`.

- [ ] **Step 3: Shellcheck**

Run: `shellcheck --severity=warning home/dot_config/bash/bashrc.d/02-shopts.bash`
Expected: no warnings.

- [ ] **Step 4: Commit**

```bash
git add home/dot_config/bash/bashrc.d/02-shopts.bash
git commit -m "$(cat <<'EOF'
Add bash shell options module with vi keybindings

Co-Authored-By: Claude <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_018ZBw71gisQk8Lv2f97XfGK
EOF
)"
```

---

## Task 4: Environment and Homebrew detection

**Files:**
- Create: `home/dot_config/bash/bashrc.d/03-env.bash`

**Interfaces:**
- Consumes: nothing.
- Produces: `EDITOR`, `PAGER`, `LESS` exported; `PATH` updated with Homebrew's shellenv when a `brew` binary is found in one of the known install locations (consumed implicitly by every later module that shells out to a Homebrew-installed tool, i.e. the completion and fzf modules in Tasks 7-8).

- [ ] **Step 1: Write `home/dot_config/bash/bashrc.d/03-env.bash`**

```bash
export EDITOR="${EDITOR:-vim}"
export PAGER="${PAGER:-less}"
export LESS="${LESS:--R}"

# A probe inspired by the zsh config's intent (find brew reliably
# across install locations) but not a trim of its implementation --
# the zsh config splices known bin dirs onto $path directly and
# assumes `brew` is already resolvable; this checks known absolute
# `brew` binary locations and evals `brew shellenv` on the first hit,
# so it works even when this shell reaches its config before
# Homebrew's own shell init has run (root shells, minimal environments).
if ! command -v brew >/dev/null 2>&1; then
  for brew_candidate in /opt/homebrew/bin/brew /usr/local/bin/brew \
    /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
    if [[ -x "$brew_candidate" ]]; then
      eval "$("$brew_candidate" shellenv)"
      break
    fi
  done
  unset brew_candidate
fi
```

- [ ] **Step 2: Verify it loads without error when brew is absent or present**

Run: `bash -c 'source home/dot_config/bash/bashrc.d/03-env.bash; echo "$EDITOR / $PAGER"'`
Expected: prints `vim / less` (or the shell's pre-existing `EDITOR`/`PAGER` if already set) with no errors, regardless of whether `brew` is installed.

- [ ] **Step 3: Shellcheck**

Run: `shellcheck --severity=warning home/dot_config/bash/bashrc.d/03-env.bash`
Expected: no warnings.

- [ ] **Step 4: Commit**

```bash
git add home/dot_config/bash/bashrc.d/03-env.bash
git commit -m "$(cat <<'EOF'
Add bash env module with Homebrew PATH detection

Co-Authored-By: Claude <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_018ZBw71gisQk8Lv2f97XfGK
EOF
)"
```

---

## Task 5: Safety and comfort aliases

**Files:**
- Create: `home/dot_config/bash/bashrc.d/04-aliases.bash`

**Interfaces:**
- Consumes: nothing.
- Produces: `ll`, `la`, `l` aliases (no later task depends on these).

- [ ] **Step 1: Write `home/dot_config/bash/bashrc.d/04-aliases.bash`**

```bash
alias rm='rm -i'
alias mkdir='mkdir -p'
alias ping='ping -c 5'
alias grep='grep --color=auto'

if [[ "$OSTYPE" == darwin* ]]; then
  alias ls='ls -G'
else
  alias ls='ls --color=auto'
fi

alias ll='ls -lAh'
alias la='ls -lAh'
alias l='ls'
```

- [ ] **Step 2: Verify aliases resolve on both OS branches**

Run: `bash -c 'source home/dot_config/bash/bashrc.d/04-aliases.bash; alias ls ll'`
Expected: `ls` aliased to `ls -G` (if run on macOS) or `ls --color=auto` (elsewhere); `ll` aliased to `ls -lAh`.

- [ ] **Step 3: Shellcheck**

Run: `shellcheck --severity=warning home/dot_config/bash/bashrc.d/04-aliases.bash`
Expected: no warnings.

- [ ] **Step 4: Commit**

```bash
git add home/dot_config/bash/bashrc.d/04-aliases.bash
git commit -m "$(cat <<'EOF'
Add bash safety and comfort aliases

Co-Authored-By: Claude <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_018ZBw71gisQk8Lv2f97XfGK
EOF
)"
```

---

## Task 6: Prompt module

**Files:**
- Create: `home/dot_config/bash/bashrc.d/05-prompt.bash`

**Interfaces:**
- Consumes: `PROMPT_COMMAND` as seeded by Task 2's `01-history.bash` — this module must append to it, not overwrite it, exactly as the history module itself did.
- Produces: `PS1` set for the session (no later task depends on its value).

- [ ] **Step 1: Write `home/dot_config/bash/bashrc.d/05-prompt.bash`**

```bash
if command -v oh-my-posh >/dev/null 2>&1; then
  eval "$(oh-my-posh init bash --config "$HOME/.config/ohmyposh/ohmyposh.json")"
else
  # Self-contained fallback: no oh-my-posh available (embedded box,
  # root shell with a stripped PATH, no network to reinstall it).
  # Still shells out once to `git rev-parse --git-dir` to locate the
  # repo, but reads .git/HEAD directly for the branch name itself
  # rather than a second git subprocess call per prompt render.
  bash_parse_git_branch() {
    local git_dir head_line
    git_dir=$(git rev-parse --git-dir 2>/dev/null) || return
    head_line=$(<"$git_dir/HEAD")
    if [[ "$head_line" == ref:\ refs/heads/* ]]; then
      printf ' (%s)' "${head_line#ref: refs/heads/}"
    else
      printf ' (%.7s)' "$head_line"
    fi
  }

  bash_prompt_command() {
    local exit_status=$?
    local color_reset='\[\e[0m\]'
    local color_prompt='\[\e[1;32m\]'
    if (( exit_status != 0 )); then
      color_prompt='\[\e[1;31m\]'
    fi
    PS1="${color_prompt}\u@\h${color_reset}:\[\e[1;34m\]\w${color_reset}\[\e[33m\]$(bash_parse_git_branch)${color_reset}\$ "
  }
  PROMPT_COMMAND="bash_prompt_command${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
fi
```

- [ ] **Step 2: Verify fallback prompt renders inside and outside a git repo**

Run: `bash -c 'PATH=/usr/bin:/bin source home/dot_config/bash/bashrc.d/05-prompt.bash; cd /tmp && bash_prompt_command && echo "$PS1"; cd - >/dev/null && bash_prompt_command && echo "$PS1"'` (restricting `PATH` to exclude wherever `oh-my-posh` is actually installed — e.g. `/opt/homebrew/bin`, `/usr/local/bin` — is what forces the fallback branch; `oh-my-posh` is an external binary, not a shell function, so `unset -f` has no effect on it)
Expected: first `PS1` has no `(branch)` suffix (`/tmp` isn't a repo); second `PS1` shows `(main)` or the current branch name when run from the repo root.

- [ ] **Step 3: Shellcheck**

Run: `shellcheck --severity=warning home/dot_config/bash/bashrc.d/05-prompt.bash`
Expected: no warnings. (If shellcheck flags the `local` usage outside a function for `color_reset`/`color_prompt` — it won't, they're inside `bash_prompt_command` — otherwise no changes needed.)

- [ ] **Step 4: Commit**

```bash
git add home/dot_config/bash/bashrc.d/05-prompt.bash
git commit -m "$(cat <<'EOF'
Add bash prompt module with oh-my-posh and git-aware fallback

Co-Authored-By: Claude <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_018ZBw71gisQk8Lv2f97XfGK
EOF
)"
```

---

## Task 7: Completion module

**Files:**
- Create: `home/dot_config/bash/bashrc.d/06-completion.bash`

**Interfaces:**
- Consumes: `brew` on `PATH` if present (from Task 4's env module).
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write `home/dot_config/bash/bashrc.d/06-completion.bash`**

```bash
if [[ -f /etc/bash_completion ]]; then
  # Debian/Ubuntu package path.
  source /etc/bash_completion
elif command -v brew >/dev/null 2>&1; then
  brew_completion="$(brew --prefix)/etc/profile.d/bash_completion.sh"
  if [[ -f "$brew_completion" ]]; then
    source "$brew_completion"
  fi
  unset brew_completion
fi
```

- [ ] **Step 2: Verify whichever branch fires does not error**

`/etc/bash_completion` exists on plenty of dev machines (any Debian box with
the `bash-completion` package, including this repo's own dev container), so
don't assume the "neither path exists" case — check both branches
explicitly:

Run: `bash -c 'source home/dot_config/bash/bashrc.d/06-completion.bash; echo OK'`
Expected: prints `OK` with no errors — this exercises whichever branch
actually applies on the machine running the test (Debian path if
`/etc/bash_completion` exists, Homebrew path if `brew` is on `PATH` and has
`bash-completion@2` installed, or the silent no-op if neither is true).

Then, separately, force the no-op path to confirm it's genuinely silent:

Run: `bash -c 'PATH=/usr/bin:/bin source home/dot_config/bash/bashrc.d/06-completion.bash; echo OK'` on a machine without `/etc/bash_completion` (or inside a minimal container that lacks it)
Expected: prints `OK` with no errors.

- [ ] **Step 3: Shellcheck**

Run: `shellcheck --severity=warning home/dot_config/bash/bashrc.d/06-completion.bash`
Expected: no warnings.

- [ ] **Step 4: Commit**

```bash
git add home/dot_config/bash/bashrc.d/06-completion.bash
git commit -m "$(cat <<'EOF'
Add bash-completion sourcing for Debian and Homebrew

Co-Authored-By: Claude <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_018ZBw71gisQk8Lv2f97XfGK
EOF
)"
```

---

## Task 8: fzf integration module

**Files:**
- Create: `home/dot_config/bash/bashrc.d/07-fzf.bash`

**Interfaces:**
- Consumes: `fzf` and (optionally) `brew` on `PATH` (from Task 4).
- Produces: nothing consumed by later tasks (last module in load order).

- [ ] **Step 1: Write `home/dot_config/bash/bashrc.d/07-fzf.bash`**

```bash
if command -v fzf >/dev/null 2>&1; then
  # fzf >= 0.48 ships its own shell-integration flag.
  if fzf --bash >/dev/null 2>&1; then
    eval "$(fzf --bash)"
  else
    # Older fzf: source the standalone key-bindings/completion pair
    # from wherever the install put them.
    for fzf_dir in \
      "$(command -v brew >/dev/null 2>&1 && echo "$(brew --prefix)/opt/fzf/shell")" \
      /usr/share/doc/fzf/examples \
      /usr/share/fzf; do
      [[ -n "$fzf_dir" && -d "$fzf_dir" ]] || continue
      [[ -f "$fzf_dir/key-bindings.bash" ]] && source "$fzf_dir/key-bindings.bash"
      [[ -f "$fzf_dir/completion.bash" ]] && source "$fzf_dir/completion.bash"
      break
    done
    unset fzf_dir
  fi
fi
```

- [ ] **Step 2: Verify it's a no-op when fzf is absent**

Run: `bash -c 'PATH=/usr/bin:/bin source home/dot_config/bash/bashrc.d/07-fzf.bash; echo OK'`
Expected: prints `OK` with no errors.

- [ ] **Step 3: Verify it wires up when fzf is present**

Run: `bash -c 'source home/dot_config/bash/bashrc.d/07-fzf.bash; bind -p | grep -c fzf || true'`
Expected: no errors; if the installed fzf is new enough for `--bash`, `FZF_DEFAULT_COMMAND` or fzf's key bindings show up (`bind -p | grep -i fzf` may be empty depending on fzf version — the pass criterion is "no error output", not a specific binding).

- [ ] **Step 4: Shellcheck**

Run: `shellcheck --severity=warning home/dot_config/bash/bashrc.d/07-fzf.bash`
Expected: no warnings.

- [ ] **Step 5: Commit**

```bash
git add home/dot_config/bash/bashrc.d/07-fzf.bash
git commit -m "$(cat <<'EOF'
Add fzf shell integration module for bash

Co-Authored-By: Claude <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_018ZBw71gisQk8Lv2f97XfGK
EOF
)"
```

---

## Task 9: Readline tuning (`~/.inputrc`)

**Files:**
- Create: `home/dot_inputrc`

**Interfaces:**
- Consumes: nothing (readline reads this independently of bash's own sourcing chain).
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write `home/dot_inputrc`**

```
# Readline tuning shared by bash (and anything else that uses
# readline). Independent of the bashrc.d sourcing chain -- readline
# reads this file itself on shell start.

set completion-ignore-case on
set show-all-if-ambiguous on
set colored-stats on
set mark-symlinked-directories on

# Type a prefix, then arrow through matching history -- the closest
# vanilla-readline equivalent to zsh-autosuggestions /
# history-substring-search, no plugin required.
#
# 02-shopts.bash turns on `set -o vi`, which switches readline's active
# keymap away from `emacs` to `vi-command`/`vi-insert`. A bare
# "key": function binding only applies to whichever keymap is selected
# at the time it's read, so these have to be bound explicitly inside
# vi-insert (where arrow keys are used) as well, or they're silently
# inert under vi mode.
"\e[A": history-search-backward
"\e[B": history-search-forward

$if mode=vi
set keymap vi-insert
"\e[A": history-search-backward
"\e[B": history-search-forward
set keymap vi-command
"\e[A": history-search-backward
"\e[B": history-search-forward
$endif
```

- [ ] **Step 2: Verify readline accepts the file**

Run: `bash -c 'bind -f home/dot_inputrc && echo OK'`
Expected: prints `OK` with no parse errors or warnings from `bind`.

- [ ] **Step 3: Verify the binding is actually live under `set -o vi`**

A clean parse (Step 2) only proves the file is syntactically valid, not that
the binding does anything in the mode this same plan turns on in Task 3.
Confirm it interactively: `bash --norc -i`, then run
`set -o vi; bind -f home/dot_inputrc`, type a few characters of a command
that's in your shell history, press `Esc` to drop into vi-command mode, then
`k` (or stay in insert mode and press the bound `\e[A` sequence directly —
e.g. by pressing the physical Up arrow), and confirm it filters history to
lines matching what you typed rather than just walking through unfiltered
history.
Expected: history search narrows to matching lines, not the plain "walk
through everything" behavior of an unbound arrow key in vi-insert mode.

- [ ] **Step 4: Commit**

```bash
git add home/dot_inputrc
git commit -m "$(cat <<'EOF'
Add shared readline config for zsh-like history search

Co-Authored-By: Claude <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_018ZBw71gisQk8Lv2f97XfGK
EOF
)"
```

---

## Task 10: Full-chain verification and lint

**Files:**
- None created — this task exercises everything from Tasks 1-9 together.

**Interfaces:**
- Consumes: the full loader chain and every module file from Tasks 1-9.
- Produces: nothing (verification-only task).

- [ ] **Step 1: Run the repo-wide lint**

Run: `just lint`
Expected: passes, including shellcheck on every new file under `home/dot_bashrc`, `home/dot_bash_profile`, `home/dot_config/bash/`.

- [ ] **Step 2: Dry-run the chezmoi diff**

Run: `chezmoi diff` from a machine with this repo as the chezmoi source (or `chezmoi diff --source home` equivalent per this repo's `.chezmoiroot` setup).
Expected: shows the new files (`~/.bashrc`, `~/.bash_profile`, `~/.inputrc`, `~/.config/bash/...`) as additions.

`home/dot_bashrc`, `home/dot_bash_profile`, and `home/dot_inputrc` are plain
`dot_` targets (always-managed, overwritten on every apply), not `create_`
(seed-once, never-clobber — the prefix this repo reserves for files like
`~/.claude/settings.json`). That's the deliberate choice here: this config
is meant to be actively maintained like the zsh config, not seeded once and
left alone. But it does mean a pre-existing `~/.bashrc` (Debian ships one
from `/etc/skel` for every new user account) or a hand-tuned `~/.inputrc`
gets silently replaced with no backup — chezmoi's own drift protection is
machine-local and doesn't warn about this. **Don't just skim the diff output
for "these three are additions"** — on each target machine, explicitly check
whether `~/.bashrc`, `~/.bash_profile`, or `~/.inputrc` already exist with
machine-local content before applying, and save off anything worth keeping
first.

- [ ] **Step 3: Apply and smoke-test interactively**

Run: `chezmoi apply --error-on-conflict ~/.bashrc ~/.bash_profile ~/.inputrc ~/.config/bash`, then open a fresh login shell (`bash -l`) and check by hand:
  - Prompt renders (oh-my-posh output, or the fallback prompt with a git branch when `cd`'d into a repo)
  - Typing a few characters then pressing `↑` filters history to matching lines
  - `ll` and `rm somefile` (interactive prompt) work
  - No stderr/warning text appears at shell start
Expected: all four checks pass with no visible errors.

- [ ] **Step 4: Commit only if Step 1-3 required fixes**

If lint or the smoke test required changes to any file from Tasks 1-9, commit them now with a message describing what was fixed. If nothing needed changing, skip this step — there is nothing to commit.

---

## Task 11: Documentation

**Files:**
- Modify: `CLAUDE.md` (repo root)

**Interfaces:**
- Consumes: nothing.
- Produces: nothing (documentation-only task).

- [ ] **Step 1: Add a `## Bash Configuration` section to `CLAUDE.md`**

Insert a new section after the existing `## Zsh Configuration` section (before `## Git Configuration`), matching the style of the surrounding tool sections:

```markdown
## Bash Configuration

- Standalone fallback config for when zsh isn't the shell in play: root/sudo
  shells, minimal or embedded Debian boxes, remote servers not managed by
  this repo. Deliberately has no plugin manager and makes no network calls
  at shell start
- bash 3.2+ compatible throughout (macOS ships a frozen bash 3.2 as
  `/bin/bash`) -- no associative arrays, no `mapfile`; anything bash-4+-only
  (`globstar`) is guarded behind a `BASH_VERSINFO` check
- `~/.bashrc` is a thin loader for `~/.config/bash/bashrc.sh`, which sources
  numbered modules from `~/.config/bash/bashrc.d/*.bash` in order (history,
  shell options/vi mode, env/Homebrew, aliases, prompt, completion, fzf).
  `~/.bash_profile` sources `~/.bashrc` so macOS Terminal.app and SSH login
  shells pick it up -- bash does not do this automatically the way zsh does
- `~/.inputrc` carries readline tuning independent of bash itself, notably
  prefix-based history search on the arrow keys -- the closest vanilla
  equivalent to zsh-autosuggestions/history-substring-search without a
  plugin
- Every optional integration (oh-my-posh, fzf, bash-completion, Homebrew) is
  probed with `command -v` / `[[ -f ]]` and silently no-ops when absent, so
  the config degrades gracefully on a stripped-down box
- Feel-only scope by design: no git aliases, no fzf-git, no
  kubectl/docker/terraform helpers ported from the zsh config -- just
  history, prompt, safety aliases, readline tuning, and vi keybindings
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "$(cat <<'EOF'
Document the standalone bash configuration in CLAUDE.md

Co-Authored-By: Claude <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_018ZBw71gisQk8Lv2f97XfGK
EOF
)"
```

---

## Self-Review Notes

- **Spec coverage:** loader chain (Task 1), history (Task 2), shopts/vi mode (Task 3), env/Homebrew (Task 4), aliases (Task 5), prompt with oh-my-posh + fallback (Task 6), completion (Task 7), fzf (Task 8), `~/.inputrc` (Task 9), testing (Task 10), documentation (Task 11) — every spec section maps to a task. Out-of-scope items from the spec (git aliases, remote/root automation) are correctly absent.
- **Placeholder scan:** no TBDs; every step has literal file content or a literal command.
- **Type/interface consistency:** `PROMPT_COMMAND` is built additively in Task 2 and Task 6 using the same `"${PROMPT_COMMAND:+; $PROMPT_COMMAND}"` pattern so neither overwrites the other regardless of load order (history loads first per the `01-`/`05-` numbering, so both accumulate correctly). Function names (`bash_history_sync`, `bash_parse_git_branch`, `bash_prompt_command`) are each defined and used within the same task/file, no cross-task name drift.

**Post-external-review fixes applied (this plan was reviewed against `SPEC_REVIEW.md` before execution started):**

- Task 1 now extends the repo's `just lint` shellcheck file list to cover the new loader files, and Task 10 extends it again to cover `bashrc.d/*.bash` once all modules exist — closing the gap where `just lint` would pass without ever actually checking this subsystem.
- Task 9's `~/.inputrc` now binds the arrow-key history search inside `$if mode=vi` / `vi-insert` and `vi-command` keymaps too, since Task 3's `set -o vi` moves readline off the `emacs` keymap the bare bindings would otherwise apply to; Task 9 also adds an interactive verification step that confirms the binding actually filters history under `set -o vi`, not just that the file parses.
- Task 6's fallback-prompt comment and verification step were corrected: it still shells out once to `git rev-parse --git-dir` (that's not free), it only avoids a *second* subprocess call for the branch name itself; and the verification step no longer claims `unset -f oh-my-posh` does anything (it's an external binary, not a shell function — restricting `PATH` is what actually forces the fallback).
- Task 7's verification step no longer assumes `/etc/bash_completion` is absent on the test machine (it exists on this repo's own dev container) — it now checks whichever branch actually fires locally, plus a separate check that the no-op path is silent when neither Debian nor Homebrew completion is present.
- Task 4's comment and interface note no longer describe the Homebrew probe as "trimmed from" the zsh config's mechanism (the zsh config splices paths directly and assumes `brew` is resolvable; this is a different, path-probing mechanism, not a trim of that one).
- Task 10 now explicitly calls out that `home/dot_bashrc`, `home/dot_bash_profile`, and `home/dot_inputrc` are plain `dot_` (always-managed) rather than `create_` (seed-once) targets — a deliberate choice since this config is meant to be actively maintained, but one that means a pre-existing `~/.bashrc`/`~/.inputrc` on a target machine gets silently overwritten, so the diff step now says to check for that explicitly rather than skim past three "additions."
