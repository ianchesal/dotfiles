# Dotfiles

This file provides guidance to AI agents working on this repository.

## Target Platforms

- macOS (zsh/Kitty), Debian Linux, and WSL2
- Changes should be portable across all three unless explicitly platform-specific

## Deployment (chezmoi)

- Deployment is **chezmoi**, not Rake. The repo is a *source*; configs are
  copied into place, not symlinked
- `.chezmoiroot` contains `home`, so the chezmoi source state lives in `home/`
  and **everything else at the repo root is invisible to chezmoi**: `asdf/`,
  `bootstrap/`, `brew/`, `claude/`, `debian/`, `docs/`, `just/`, `nvim/`,
  `script/`, `slack/`, `terminal/`, `winterm/`, plus `justfile`, `README.md`,
  `TODO.md`, and the `.claude/`, `.devcontainer/` and `.github/` dirs
- Two chezmoi control files live outside `home/` and inside it respectively:
  `.chezmoiroot` at the repo root, and `home/.chezmoiremove`, which lists paths
  chezmoi should delete from a machine on the next apply
- Source naming: `home/dot_config/tmux/` → `~/.config/tmux/`, `dot_` at **every**
  level. `chezmoi add` applies the prefixes for you — don't hand-name files
- Prefixes in use: `executable_` (exec bit, 13 entries), `create_` (seed once,
  never clobber — one entry, `home/dot_claude/create_private_settings.json`, and
  what protects `~/.claude/settings.json`), `symlink_` (the entry's contents are
  the link target — one entry, `symlink_nvim.tmpl`),
  `run_once_before_*` (one entry, the Brewfile bootstrap) and `run_once_after_*`
  (four entries, setup scripts). Ordering matters: `before` runs ahead of any
  config being written, `after` once everything has landed
- **In templates the repo root is `.chezmoi.workingTree`**, never
  `.chezmoi.sourceDir` (which resolves to `<repo>/home`)
- **`nvim/` is deliberately NOT in the source state.** It stays at the repo root
  and `~/.config/nvim` is a `symlink_` entry pointing at it, so editing a plugin
  spec is instantly live and `update.lua` keeps writing `pins.json` beside the
  lockfile. Everything under `~/.config/nvim` is invisible to `chezmoi
  status`/`diff`/`verify` — that is intended
- Every config deploys on every platform. No OS gating: a kitty config on Linux
  is inert and not worth a template guard
- `~/.work_machine` stays a **runtime** check
  (`home/dot_config/gh-dash/executable_gh-dash.sh` reads the file itself) so
  tmux popups and cron agree with interactive shells. Both `config.yml` and
  `config-work.yml` deploy everywhere
- chezmoi does **not** back up what it replaces, and its drift protection is
  machine-local (`chezmoistate.boltdb` is not in the repo). On a machine chezmoi
  has never written to, `apply` replaces pre-existing files with no prompt —
  `chezmoi diff` first is the only safeguard

## Task Running (just)

- `just` owns the "update everything" fan-out and the tool utilities that have
  no chezmoi equivalent. It **deploys nothing** — that is chezmoi's job
- Replaced a Rakefile in September 2026. The point was to stop needing a Ruby
  runtime, bundler and gems to shell out; Ruby stays on these machines for work
  and for Mason's `ruby-lsp`/`rubocop`, but nothing in this repo bootstraps it
- Root `justfile` holds the fan-out (`update`), `lint`, `test`, and
  `install-runtimes`. Per-tool recipes live in `just/<tool>.just` and are
  addressed with `::` — `just brew::update`, `just asdf::prune-preview`
- `export REPO := justfile_directory()` in the root justfile is how modules find
  the repo: **a module recipe runs with `just/` as its working directory**, not
  the repo root and not the tool's directory, so always reach other paths
  through `$REPO` — never a relative path. `winterm::install` copying
  `$REPO/winterm/settings.json` is the one recipe that touches a tool directory
- Each `just/<tool>.just` must repeat `set shell := ["bash", "-eu", "-o", "pipefail", "-c"]`
  — modules do **not** inherit settings from the root justfile
- A module cannot depend on a sibling module's recipe. Either compose them in the
  root justfile (`install-runtimes`) or shell back through
  `just --justfile "$REPO/justfile" <mod>::<recipe>` (`asdf::install`)
- Anything with real logic is a script in `script/`, not a recipe: `asdf-prune`,
  `gem-cleanup`, `nvim-commit`, `gen-claude-completions.py`. Scripts take env
  var seams (`ASDF_BIN`, `GEM_BIN`, `TOOL_VERSIONS`) so `script/tests/*.test.sh`
  can drive them against fakes
- `script/asdf-prune` and `script/gem-cleanup` need bash 4+ (`mapfile`); macOS
  ships bash 3.2, so `brew/Brewfile` installs bash and both scripts fail loudly
  if they end up on an older one

## Bootstrapping a new machine

- One command: `sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply
  --source="$HOME/src/dotfiles" ianchesal/dotfiles`. Only `curl` and `git` need
  to pre-exist (Homebrew's installer needs them)
- `home/run_once_before_20-brew-bundle.sh` is what makes that true: it installs
  Homebrew and everything in `brew/Brewfile` **before** any config is written,
  so the tools exist before their configs land. Without it a fresh machine gets
  a zsh config with no zsh and a `dfu` that calls a `just` that was never
  installed
- It reads `CHEZMOI_WORKING_TREE` (the repo root), **not** `CHEZMOI_SOURCE_DIR`
  — `.chezmoiroot` makes the latter `<repo>/home`, and `brew/` sits outside the
  source state
- Adding any new `run_once_*` script makes it run once on **every** existing
  machine at its next `chezmoi apply`, not just on new ones
- Homebrew 7 refuses to load a formula/cask from a non-official tap until it is
  trusted, and the trust store is **machine-local**
  (`$XDG_CONFIG_HOME/homebrew/trust.json`, else `~/.homebrew/trust.json`) so
  chezmoi cannot carry it. `brew/trusted` is the repo's declared list and
  `script/brew-trust` applies it; both bootstrap paths run it *before* `brew
  bundle`, and the script is called directly rather than via `just` because
  `just` is one of the things `brew bundle` installs. Adding a third-party tap
  to `brew/Brewfile` **requires** a matching `brew/trusted` entry or the next
  fresh machine fails to bootstrap — prefer a `formula`/`cask` entry over a
  `tap` entry, which grants trust to everything in that repo forever
- Two steps stay out of `chezmoi apply` on purpose: `just shell::set-default`
  (`/etc/shells` + `chsh` needs sudo and can lock you out of a box) and `just
  install-runtimes` (slow, and compiles Ruby)
- `just doctor` is a read-only health check — core tooling, bash 4+, chezmoi
  source, Brewfile coverage, third-party tap trust, asdf runtimes vs
  `~/.tool-versions`, login shell.
  Run it after a bootstrap or when something feels off
- `bootstrap/cloud-workstation.sh` is now a thin wrapper over exactly that path,
  plus the kitty terminfo a remote box needs

## Build/Test/Lint Commands

- Deploy dotfiles: `chezmoi apply --error-on-conflict` (preview first with `chezmoi diff`)
- Deploy one path: `chezmoi apply --error-on-conflict ~/.config/tmux`
- Daily update: `dfu` (pull → diff → confirm → apply → `just update` → `zinit update`)
- Start managing a new file: `chezmoi add <path>`; capture a live edit: `chezmoi re-add <path>`
- Stop managing: `chezmoi forget <path>`; remove entirely: `chezmoi destroy <path>`
- List all tasks: `just --list --list-submodules` (just owns **only** the update fan-out and a few tool utilities — it deploys nothing, and there is no `all` or `clean`)
- See `docs/chezmoi-workflows.md` for the full day-to-day workflows
- Verify chezmoi still behaves as this layout assumes (run after a chezmoi
  upgrade): `script/verify-chezmoi-assumptions.sh` — scratch-dir only, never
  touches the real home
- Health-check a machine: `just doctor`
- Lint shell scripts and justfiles: `just lint` — shellcheck (`--severity=warning`),
  an `ast.parse` syntax check on `script/gen-claude-completions.py`, and
  `just --fmt --check`. This is exactly what CI runs (`.github/workflows/ci.yml`).
  Markdown is **not** linted: there is no markdown linter in the Brewfile, in
  `just lint`, or in CI
- Run the shell script tests: `just test-scripts`; those plus the nvim specs: `just test`
- Update configurations: `just update`
- Update Neovim plugins (30-day delayed): `just nvim::update`
- Preview eligible Neovim plugin updates without applying: `just nvim::outdated`
- Check and commit Neovim dependency updates: `just nvim::commit`
- Remove Mason packages no longer wanted by the config: `just nvim::mason-prune` (runs automatically as the last step of `nvim::update`)
- Preview which Mason packages would be pruned: `just nvim::mason-outdated`
- Run Neovim machinery tests: `nvim --headless -u NONE -l nvim/tests/<name>_spec.lua` (delay, gitops, loader)
- Check for Oh My Posh updates: `just ohmyposh::check-update`
- Update Oh My Posh: `just ohmyposh::update`
- Reload tmux config in all sessions: `just tmux::reload`
- Update zsh plugins: `zinit self-update && zinit update` (also run by `dfu`)
- Install the Rust toolchain: `just rust::install`
- Update rustup and Rust toolchains: `just rust::update`
- Update Homebrew packages: `just brew::update`
- Trust the third-party taps declared in `brew/trusted`: `just brew::trust`
- Update yt-dlp: `just ytdlp::update`
- Update gcloud components: `just gcloud::update`
- Uninstall asdf tool versions older than the one in use: `just asdf::prune` (`FORCE=1` skips the confirmation prompt)
- Preview which asdf tool versions would be pruned: `just asdf::prune-preview`

## Code Style Guidelines

- Shell: bash with `set -euo pipefail`; must pass `shellcheck --severity=warning`
- justfiles: must pass `just --fmt --check`
- Line length limit: 160 characters
- Indentation: 2 spaces
- Prefer single quotes for strings unless interpolation is needed
- Use snake_case for methods and variables
- Shell scripts should use proper error handling
- Document every `just` recipe with a `#` comment on the line directly above it — that comment is what `just --list` shows
- Method naming: Use descriptive names that reflect functionality
- File organization: Group related files by tool/function in separate directories

## AeroSpace Configuration

- A tiling window manager that uses the tree paradigm made popular by the [i3 window manager](https://i3wm.org/)
- Located in `.config/aerospace` following XDG directory structure
- Uses a TOML format for configuration
- The guide for how to configure AeroSpace can be found [here](https://nikitabobko.github.io/AeroSpace/guide)
- The Github project for AeroSpace can be found [here](https://github.com/nikitabobko/AeroSpace)

## Tmux Configuration

- Source state is `home/dot_config/tmux/`, deployed to `~/.config/tmux`. It is
  **copied like everything else, not symlinked** — `nvim/` is the only `symlink_`
  entry in the repo, so a tmux edit needs a `chezmoi apply` to go live
- Main configuration in `tmux.conf`, theme in `theme.conf`. Also present:
  `theme-gcw.conf` (cloud-workstation variant), `tmux-minimal.conf`, and a
  `workmux/` subdirectory of helper scripts
- Uses TPM (Tmux Plugin Manager) for plugins, installed to `~/.config/tmux/plugins/`
- VHS Era theme with powerline-style status bar segments and double-arrow separators
- Custom helper scripts live alongside the config in `home/dot_config/tmux/` and
  carry the `executable_` prefix — `executable_git-aware-popup.sh` deploys as
  `~/.config/tmux/git-aware-popup.sh`
- Plugin-specific configuration is grouped in labeled sections within `tmux.conf` (not inline with plugin declarations)
- Status bar uses the VHS Era color palette defined in the Oh My Posh section
- TPM bootstrap (`run '~/.config/tmux/plugins/tpm/tpm'`) must always be the last line in `tmux.conf`

## Neovim Configuration

- Self-managed on Neovim 0.12's native `vim.pack` — no plugin-manager framework (migrated off LazyVim June 2026)
- One plugin per file in `./nvim/lua/plugins/*.lua`; each returns `{ src, policy, priority?, config? }`:
  - `src`: full https URL (vim.pack passes it verbatim to `git clone` — no `owner/repo` shorthand)
  - `policy`: `{ mode = "commit" }` (default, 30-day delayed) / `"tag"` (delayed stable semver releases) / `"exempt"` (no delay; also the urgent-update escape hatch); optional `days = N` overrides the window
  - `priority`: lower runs `config()` earlier (colorscheme 10, mini-icons 14, snacks 15, treesitter 20, which-key 25, mason→lspconfig 30–32, blink 40, default 50)
  - `config()`: plain `setup()` calls + `vim.keymap.set` — NO lazy.nvim idioms (`dependencies`/`event`/`keys`/`cmd`/`build`/`opts` spec fields)
- Updates are delayed by first-observed timestamps: `./nvim/pins.json` is authoritative (GENERATED — never hand-edit); `./nvim/nvim-pack-lock.json` is vim.pack's derived lockfile; both must agree and travel in one commit (`just nvim::commit` enforces consistency)
- Update machinery: `./nvim/lua/pack/` (delay.lua pure core, gitops.lua git layer, loader.lua) + `./nvim/scripts/update.lua`; tests in `./nvim/tests/*_spec.lua`
- The updater MUST run with `-u NONE` — init.lua pre-registering vim.pack specs would freeze update targets (re-adds are no-ops)
- A plugin spec with no pin entry is a hard startup error; `just nvim::update` is the only path that creates pins (never fall back to branch tips)
- Adding a plugin: new spec file, then `just nvim::update` to bootstrap its delayed pin; removing: delete the spec file, then clean up pin/lockfile entries and the on-disk clone
- Plugin-bound keymaps live in that plugin's spec file; global keymaps in `./nvim/lua/config/keymaps.lua`; autocmds in `./nvim/lua/config/autocmds.lua`; which-key groups in `./nvim/lua/plugins/which-key.lua`
- nvim-treesitter pins the `main` branch (post-rewrite API — no module system); endwise and contextindent carry commented compat shims in their spec files; lspconfig.lua uses one pcall-guarded internal mason-lspconfig API (check on its pin bumps)
- Mason packages are NOT tracked by the repo, so dropping a tool/LSP from config leaves orphans on every other machine; `just nvim::mason-prune` reconciles them (runs as the last step of `nvim::update`). The authoritative "keep" set is assembled at runtime: `mason.lua`'s `ensure_installed` plus the Mason packages backing enabled servers in `lspconfig.lua`, both registered into `./nvim/lua/pack/mason_desired.lua` from their `config()`. The prune script (`./nvim/scripts/mason_prune.lua`) loads the FULL config (NOT `-u NONE`, unlike the updater) and refuses to run if any source failed to register (guards against over-deletion on a startup error)
- Lua: stylua format (2-space indent, 120 column width); requires Neovim 0.12+; updater needs `jq` and `git`

## Zsh Configuration

- Source state is `home/dot_config/zsh/`, deployed to `~/.config/zsh`. The
  `dot_zshrc`/`dot_zprofile` entries there become `~/.config/zsh/.zshrc` and
  `.zprofile`; `~/.zshenv` comes from `home/dot_zshenv` and is what points ZDOTDIR
  at the XDG location
- Zsh files are modular and stored in `home/dot_config/zsh/zshrc.d/`
- Using `zdharma-continuum/zinit` for zsh plugin support
- Custom functions go in `home/dot_config/zsh/functions/` with one function per file
- Custom completions go in `home/dot_config/zsh/completions/` following zsh-completions format
- Aliases go in `home/dot_config/zsh/zshrc.d/04-aliases.zsh`
- Naming convention for zshrc.d files: numeric prefix for load order (e.g., `02-functions.zsh`) (but only if load order is strictly required); unordered concerns use a bare name, as `machine.zsh` does
- Global aliases use suffix format (e.g., `alias -g G='| grep -E'`)
- History settings: large history size, ignore duplicates, share across sessions
- Use descriptive comments for functions and aliases
- Follow existing patterns for tool-specific configurations (each tool has its own file)
- NEVER recommend the forgit zsh plugin -- I hate it
- Machine identity lives in `zshrc.d/machine.zsh`: `DOTFILES_MACHINE` (gcw vs
  other, detected from `/etc/workstation-startup.d`) and `WORK_MACHINE`, which is
  exported from the `~/.work_machine` flag file. That file is the source of truth
  for work-vs-personal — repo code tests the file (`[ -f ]` in
  `script/gem-cleanup` and in shell), never the exported variable, so the answer is the
  same in tmux popups, cron and other detached contexts. `touch` to enable, `rm`
  to disable; it is machine-local and nothing in the repo manages it

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
  `~/.bash_profile` sources `~/.profile` first (if present), then
  `~/.bashrc`, so macOS Terminal.app and SSH login shells pick up the config
  -- bash does not do this automatically the way zsh does. `~/.bashrc` has a
  re-entrancy guard (`BASH_RC_LOADED`) so this can't double-load the
  bashrc.d chain even though Debian/WSL2's `~/.profile` also sources
  `~/.bashrc` itself
- `~/.inputrc` carries readline tuning independent of bash itself, notably
  prefix-based history search on the arrow keys -- the closest vanilla
  equivalent to zsh-autosuggestions/history-substring-search without a
  plugin
- Every optional integration (oh-my-posh, fzf, bash-completion, Homebrew) is
  probed with `command -v` / `[[ -f ]]` and silently no-ops when absent, so
  the config degrades gracefully on a stripped-down box
- Scope is feel plus git. History, prompt, safety aliases, readline
  tuning and vi keybindings, and `08-git.bash` -- the zsh `g*`/`gh*`
  alias block ported over, since a missing `gs` or `gco` is exactly what
  makes a shell feel foreign. The `git com`/`fixup`/`main-branch` halves
  of `gcom`/`gfu`/`grim` need no porting; they are git-config aliases
  and already resolve in bash. `08-git.bash` also wires `__git_complete`
  onto the aliases (sourcing git's completion itself first, because
  bash-completion v2 lazy-loads it and leaves `__git_complete` undefined
  at shell start) so `gco <TAB>` offers branches, not filenames
- Still deliberately absent: fzf-git, and the kubectl/docker/terraform
  helpers from the zsh config
- Normal deployment is chezmoi, same as everything else. For a machine you
  don't want to (or can't) chezmoi-manage at all -- no git, no Homebrew, no
  repo checkout -- `bootstrap/bash-only.sh` fetches just these files
  straight from GitHub raw content and writes them into place, backing up
  anything already there first: `curl -fsSL
  https://raw.githubusercontent.com/ianchesal/dotfiles/main/bootstrap/bash-only.sh
  | bash`

## Git Configuration

- Source state is `home/dot_config/git/`, deployed to `~/.config/git`
- Main configuration in `config`, which ends with `[include] path = local`.
  That `local` file is **not tracked** — it is per-machine identity and overrides,
  so it is absent from the source state by design and exists only on the box
- Use descriptive git aliases that enhance workflow speed
- Git hooks stored in `hooks/` (`executable_pre-push` prevents pushing fixup
  commits; `workmux-status` backs the worktree tooling)
- GitHub CLI configuration in `home/dot_config/gh/config.yml` with helpful aliases
- GitHub Dashboard config in `home/dot_config/gh-dash/config.yml` for PR
  management, with `config-work.yml` alongside it as a work-machine overlay
  (`include`s the base config, replaces `prSections` with
  `org:persona-id`-scoped ones); `executable_gh-dash.sh` in that same directory
  selects between them on the `~/.work_machine` flag and is what tmux
  `prefix + h` and the `ghd` alias invoke. Note `gh-dash/` is its own
  `dot_config` entry — it is **not** nested under `git/`
- Delta used for enhanced diffs with side-by-side display
- Conventions for commit messages: no fixup commits in pushed branches
- Git workflow relies heavily on custom aliases and integrations
- Repository configuration uses a rebase workflow with `autosetuprebase = always`

## Kitty Configuration

- Located in `.config/kitty` following XDG directory structure
- Main configuration in `kitty.conf` organized with fold markers for sections
- Theme management through include files (e.g., `include ./tokyonight_night.conf`)
- Multiple theme options available in the `themes/` directory
- Font configuration uses JetBrains Mono with appropriate size settings
- Terminal features: copy on select, shell integration, and hyperlink support
- Tab bar configuration with powerline style and custom tab titles
- Custom keyboard shortcuts for navigation and terminal management
- Cursor customization with beam shape
- Extended scrollback buffer (10,000 lines) for terminal history
- Remote control enabled for integration with other tools

## Oh My Posh Configuration

- Located in `.config/ohmyposh` following XDG directory structure
- Configured via JSON in `ohmyposh.json` using the official schema
- Custom VHS Era theme with defined color palette
- Prompt structured in multiple blocks (left-aligned, right-aligned, newline prompt)
- Features path segment with powerlevel style
- Git integration showing branch, changes, and ahead/behind status
- Programming language version display (Node, PHP, Python, Julia, Ruby, Go)
- Execution time tracking for commands
- SSH session information display
- Command status indicator in prompt color
- Custom tooltips for AWS, GCP, and Kubernetes tools
- Managed via Homebrew; `just ohmyposh::check-update` only reports a waiting update, so a prompt change is never a surprise mid-run

## Claude Configuration

- Source state is `home/dot_claude/`, deployed to `~/.claude` — **not** under
  `.config/`. Claude Code does not honour XDG for its own directory, so this one
  config deliberately breaks the XDG pattern the rest of the repo follows
- Global memory file is `home/dot_claude/CLAUDE.md`, deployed to
  `~/.claude/CLAUDE.md`, for persistent context across Claude Code sessions
- Memory file maintains important context, preferences, and recurring tasks
- Structure memory file with clear section headers and descriptive content
- Memory file content should be concise and focused on high-value information
- Never include project-specific terminology, conventions, and preferences in the global memory file — those belong in the project's CLAUDE.md
- Document complex workflows that should be remembered across sessions
- Skills dividing line: skills for working *on this repo* (e.g.,
  `managing-nvim-plugins`) go in `.claude/skills/` at the repo root — project-scoped,
  outside the chezmoi source state, only loaded in this repo. Skills wanted in every
  session everywhere (e.g., `morning-startup`, `daily-wrap`) go in
  `home/dot_claude/skills/` — chezmoi source state, deployed to `~/.claude/skills/`
- Global skills are **copied, not symlinked**. `~/.claude/skills` is a real directory,
  so a skill edited in the repo is not live until the next `chezmoi apply` — unlike
  `nvim/`, which is a `symlink_` entry and takes effect instantly. Editing a global
  skill is a two-step job: change it here, then apply. Conversely, editing one directly
  under `~/.claude/skills/` puts it out of sync with the repo and the next `chezmoi
  apply` silently overwrites it — `chezmoi re-add` captures such an edit instead
- There is no `claude/skills/` directory; `claude/` at the repo root holds only
  `apt-claude.sh`
- `~/.claude/settings.json` is seeded by
  `home/dot_claude/create_private_settings.json` and then never touched again
  (`create_` = write if absent). The live file is not tracked — it is per-machine
  state and on work machines carries persona/allowedTools config that must never
  be committed
- **The tracked seed is itself the curated set of portable defaults.** There is no
  separate skeleton file and no `claude-settings` skill; both were retired in
  September 2026 once the seed and the skeleton had converged on the same content.
  To change the defaults, hand-edit `create_private_settings.json`
- **Never `chezmoi re-add ~/.claude/settings.json`.** The live file carries
  `allowedTools`, `enabledPlugins`, `env`, `extraKnownMarketplaces` and
  `feedbackSurveyState` on top of the seed — machine-local keys, and `env` plus
  `allowedTools` are exactly what this public repo must not publish. Editing the
  seed by hand is the only safe direction
- `create_` will **not** update a machine that already has a `settings.json`, and
  templating does not change that (verified: `create_` + `.tmpl` leaves an
  existing file alone even under `chezmoi apply --force`). Improved defaults
  therefore reach fresh machines only; to re-seed an existing one, delete
  `~/.claude/settings.json` and apply. If that ever needs to be automatic, the
  primitive is `modify_` — its script receives the current file on stdin — not a
  template
- The zsh completion spec (`~/.config/zsh/completions/_claude`) is deliberately
  **not** in the source state. `script/gen-claude-completions.py` writes it
  straight to the live dir, because the spec is parsed from the locally
  installed `claude --help` and is therefore per-machine: tracking it left the
  repo dirty after every version bump, and `chezmoi apply` on a second machine
  then overwrote its correct spec with the first machine's. Same category as the
  `_kubectl` spec `zshrc.d/kubernetes.zsh` caches at runtime. It survives
  `chezmoi apply` because `home/dot_config/zsh/completions/` carries no
  `exact_` prefix, and it is on fpath already. `just claude::update`
  regenerates it on a version change and calls the script with `--if-missing`
  to seed a machine that has none, so a fresh box gets one without a manual
  step. The script honours `ZDOTDIR` and owns the destination path — don't
  duplicate it in a recipe
- Work-specific Claude config stays **out of the source state**, because this
  repo is public. `~/.claude/oracle-gateway.json` (the `--settings` file that
  points Claude Code at Persona's Anthropic proxy) was tracked until September
  2026 and is now machine-local and unmanaged — same category as
  `settings.json` above. It holds no secret, but the internal hostname isn't
  worth publishing, and it's inert on a personal machine. Copy it by hand to a
  new work box; don't `chezmoi add` it back

## Rust Configuration

- Managed by `rustup` (the canonical Linux/macOS installer), not Homebrew or apt
- Recipes in `just/rust.just`; shell integration in `zsh/zshrc.d/rust.zsh`
- Installed with `--no-modify-path` so the installer never edits the managed `.zshrc`; `rust.zsh` sources `~/.cargo/env` instead to put `~/.cargo/bin` on PATH
- `just rust::install` is idempotent — it detects an existing rustup (on PATH or in `~/.cargo/bin`) and skips the installer
- Removing the toolchain is deliberately never automatic; use the explicit `just rust::uninstall`
- `just install-runtimes` runs `rust::install` before `asdf::install`: ruby-build only compiles YJIT/ZJIT into Ruby when a Rust toolchain exists at build time. `asdf::install` also shells back through the root justfile to enforce that ordering on its own, because a just module cannot depend on a sibling module's recipe

