# Standalone Bash Fallback Configuration

## Purpose

Ian's daily shell is zsh with zinit-managed plugins. This spec adds a
second, independent shell configuration for bash, used when zsh isn't
the shell in play: `su -`/`sudo -i` root shells, minimal or embedded
Debian boxes, and remote servers he doesn't own. It should feel
comfortable the way the zsh setup does (history, prompt, sane
defaults) without depending on any plugin manager or network access at
shell-start time, and must degrade gracefully on a box that has none
of Homebrew, oh-my-posh, fzf, or bash-completion installed.

Deployment target is chezmoi, same as the rest of this repo — this
configures Ian's own accounts on his own machines. Copying the
resulting files onto a root shell or a borrowed remote box is a manual
step outside chezmoi's scope.

## Constraints

- **bash 3.2+ compatible.** macOS ships a GPLv2-frozen bash 3.2 as
  `/bin/bash` and it's a live possibility on old/embedded Debian too.
  No associative arrays, no `mapfile`, no `${var,,}` case conversion.
  Anything bash-4+-only (e.g. `globstar`) must be guarded behind a
  `BASH_VERSINFO` check.
- **No plugin manager, no network calls at shell start.** Every
  external dependency (oh-my-posh, fzf, bash-completion) is optional
  and probed with `command -v` / `[[ -f ]]`; absence must be silent,
  not an error or a degraded prompt with visible failures.
- **macOS and Debian both.** Same portability bar as the rest of this
  repo — no OS gating beyond what's structurally required (e.g.
  `ls --color=auto` vs `ls -G`).
- **Feel-only scope.** This is not a port of the zsh alias/function
  library. Only comfort/safety items that make a bare bash shell
  pleasant: history behavior, prompt, a handful of safety aliases,
  readline tuning, vi keybindings. No git aliases, no fzf-git, no
  kubectl/docker helpers.

## Layout

Chezmoi source paths (repo root is `home/`, `.chezmoiroot`):

```
home/dot_bashrc                        -> ~/.bashrc            (loader)
home/dot_bash_profile                  -> ~/.bash_profile      (login-shell shim)
home/dot_inputrc                       -> ~/.inputrc           (readline tuning)
home/dot_config/bash/dot_bashrc.sh     -> ~/.config/bash/bashrc.sh
home/dot_config/bash/bashrc.d/*.bash   -> ~/.config/bash/bashrc.d/*.bash
```

`~/.bashrc` is a thin loader (mirrors the zsh setup's `ZDOTDIR`
indirection, adapted for bash's lack of a `ZDOTDIR` equivalent):

```bash
[[ -f "$HOME/.config/bash/bashrc.sh" ]] && source "$HOME/.config/bash/bashrc.sh"
```

`~/.bash_profile` sources `~/.bashrc`. This is required, not
cosmetic: bash only auto-sources `.bashrc` for non-login interactive
shells. macOS Terminal.app and SSH sessions start login shells, which
read `.bash_profile`/`.profile` instead — without this shim the entire
config silently never runs on exactly the platforms this is for.

`~/.config/bash/bashrc.sh` sources every `*.bash` file in
`bashrc.d/` in filename order, skipping names starting with `~`
(matching the zsh loader's convention).

## Modules (`bashrc.d/`)

- **`01-history.bash`** — `HISTSIZE=10000`, `HISTFILESIZE=20000`,
  `HISTCONTROL=ignoredups:erasedups`, `shopt -s histappend`,
  `HISTTIMEFORMAT`, and shared history across concurrent sessions via
  `PROMPT_COMMAND` appending `history -a; history -c; history -r`.
- **`02-shopts.bash`** — `shopt -s checkwinsize extglob`; `globstar`
  only under `(( BASH_VERSINFO[0] >= 4 ))`; `set -o vi` (matches Ian's
  zsh vi-mode preference — accepted trade-off that a root/remote shell
  will be in vi mode too).
- **`03-env.bash`** — `EDITOR`/`PAGER`/`LESS` defaults; Homebrew
  `shellenv` detection trimmed from the zsh config's brew-location
  probe (checks `/opt/homebrew`, `/usr/local`, linuxbrew paths) so
  PATH is sane on a mac or linuxbrew box that reaches this config
  before Homebrew's own shell init has run.
- **`04-aliases.bash`** — `rm -i`, `mkdir -p`, `ping -c 5`,
  `ls --color=auto` (Linux) / `ls -G` (Darwin, via `$OSTYPE` check),
  `grep --color=auto`, `ll='ls -lAh'`, `la='ls -lAh'`, `l=ls`.
- **`05-prompt.bash`** — if `oh-my-posh` is on `PATH`:
  `eval "$(oh-my-posh init bash --config ~/.config/ohmyposh/ohmyposh.json)"`.
  Otherwise a self-contained `PS1` built from a `bash_prompt_command`
  function: exit-status-colored prompt symbol, cwd, and git branch via
  a local `parse_git_branch` (reads `.git/HEAD` directly — no `git`
  subprocess call per prompt, keeping it fast on slow/remote links).
- **`06-completion.bash`** — sources `/etc/bash_completion` (Debian)
  or `$(brew --prefix)/etc/profile.d/bash_completion.sh` (mac,
  bash-completion@2) if present; otherwise no-op. Requires `shopt -s
  progcomp` (bash default) — no explicit action needed there.
- **`07-fzf.bash`** — if `fzf` is on `PATH`: prefer `eval "$(fzf
  --bash)"` (fzf ≥0.48); fall back to sourcing the older
  `key-bindings.bash`/`completion.bash` pair from fzf's install-time
  known locations (`/usr/share/doc/fzf/examples/`,
  `$(brew --prefix)/opt/fzf/shell/`) for older fzf versions. No-op if
  fzf is absent.

## Readline (`~/.inputrc`)

Not bash-specific, but this is the highest-leverage single file for
"feels like zsh" comfort in vanilla bash:

- `"\e[A": history-search-backward` / `"\e[B": history-search-forward`
  — type a prefix, arrow-key through matching history (approximates
  zsh-autosuggestions / history-substring-search without a plugin)
- `set completion-ignore-case on`
- `set show-all-if-ambiguous on`
- `set colored-stats on`
- `set mark-symlinked-directories on`

## Error Handling / Degradation

Every optional integration is a guard clause, not a try/catch:
`command -v oh-my-posh >/dev/null 2>&1`, `[[ -f
/etc/bash_completion ]]`, etc. A box with none of Homebrew, oh-my-posh,
fzf, or bash-completion installed gets: sane history, the safety
aliases, readline history-search, vi mode, and the hand-rolled
git-aware prompt — nothing errors, nothing prints a warning at shell
start.

## Testing

- `shellcheck --severity=warning` on every new file (already required
  repo-wide by `just lint`).
- Manual smoke test: `bash --rcfile home/dot_config/bash/dot_bashrc.sh`
  won't exercise the login-shell path, so also verify with `bash -l`
  after a `chezmoi apply` on both a macOS and a Debian box (or a
  Debian container for the latter), confirming: prompt renders, `↑`
  history search works, `git` branch shows inside a repo, aliases are
  live, and no stderr output appears at shell start.
- No automated test harness (`script/tests/*.test.sh`) is warranted —
  these are declarative config files with guard clauses, not scripts
  with branching logic worth unit-testing in isolation. Manual
  verification during rollout is proportionate.

## Documentation

- Add a `## Bash Configuration` section to the root `CLAUDE.md`
  alongside the existing Zsh/Git/Kitty sections, describing the
  loader chain and the module list at the same level of detail as the
  other tool sections.
- No new `just` recipes — this is pure chezmoi-deployed config, same
  as tmux/kitty/ohmyposh.

## Out of Scope

- Git aliases, fzf-git, kubectl/docker/terraform helpers — the zsh
  config's tool-specific alias files are not being ported.
- Any change to the zsh configuration.
- Automating deployment to root or to remote boxes Ian doesn't own —
  those remain a manual copy.
