# Dotfiles

This file provides guidance to AI agents working on this repository.

## Target Platforms

- macOS (zsh/Kitty), Debian Linux, and WSL2
- Changes should be portable across all three unless explicitly platform-specific

## Deployment (chezmoi)

- Deployment is **chezmoi**, not Rake. The repo is a *source*; configs are
  copied into place, not symlinked
- `.chezmoiroot` contains `home`, so the chezmoi source state lives in `home/`
  and everything else at the repo root (Rakefile, `brew/`, `script/`, `docs/`,
  `nvim/`) is invisible to chezmoi
- Source naming: `home/dot_config/tmux/` → `~/.config/tmux/`, `dot_` at **every**
  level. `chezmoi add` applies the prefixes for you — don't hand-name files
- Prefixes in use: `executable_` (exec bit), `create_` (seed once, never
  clobber — this is what protects `~/.claude/settings.json`), `symlink_` (the
  entry's contents are the link target), `run_once_after_*` (setup scripts)
- **In templates the repo root is `.chezmoi.workingTree`**, never
  `.chezmoi.sourceDir` (which resolves to `<repo>/home`)
- **`nvim/` is deliberately NOT in the source state.** It stays at the repo root
  and `~/.config/nvim` is a `symlink_` entry pointing at it, so editing a plugin
  spec is instantly live and `update.lua` keeps writing `pins.json` beside the
  lockfile. Everything under `~/.config/nvim` is invisible to `chezmoi
  status`/`diff`/`verify` — that is intended
- Every config deploys on every platform. No OS gating: a kitty config on Linux
  is inert and not worth a template guard
- `~/.work_machine` stays a **runtime** check (`git/gh-dash/gh-dash.sh` reads the
  file itself) so tmux popups and cron agree with interactive shells. Both
  `config.yml` and `config-work.yml` deploy everywhere
- `script/cutover` is migration-only — it converts a live symlink-into-the-repo
  into a real directory without losing untracked state, and refuses to run twice
- chezmoi does **not** back up what it replaces, and its drift protection is
  machine-local (`chezmoistate.boltdb` is not in the repo). On a machine chezmoi
  has never written to, `apply` replaces pre-existing files with no prompt —
  `chezmoi diff` first is the only safeguard

## Build/Test/Lint Commands

- Deploy dotfiles: `chezmoi apply --error-on-conflict` (preview first with `chezmoi diff`)
- Deploy one path: `chezmoi apply --error-on-conflict ~/.config/tmux`
- Daily update: `dfu` (pull → diff → confirm → apply → `rake update` → `zinit update`)
- Start managing a new file: `chezmoi add <path>`; capture a live edit: `chezmoi re-add <path>`
- Stop managing: `chezmoi forget <path>`; remove entirely: `chezmoi destroy <path>`
- List all rake tasks: `rake -T` (Rake now owns **only** the update fan-out — there is no `rake all` or `rake clean`)
- See `docs/chezmoi-workflows.md` for the full day-to-day workflows
- Run Rubocop checks: `rake rubocop:check`
- Auto-correct Rubocop issues: `rake rubocop:auto_correct`
- Update configurations: `rake update`
- Update Neovim plugins (30-day delayed): `rake nvim:update`
- Preview eligible Neovim plugin updates without applying: `rake nvim:outdated`
- Check and commit Neovim dependency updates: `rake nvim:commit`
- Remove Mason packages no longer wanted by the config: `rake nvim:mason_prune` (runs automatically as the last step of `nvim:update`)
- Preview which Mason packages would be pruned: `rake nvim:mason_outdated`
- Run Neovim machinery tests: `nvim --headless -u NONE -l nvim/tests/<name>_spec.lua` (delay, gitops, loader)
- Check for Oh My Posh updates: `rake ohmyposh:check_update`
- Update Oh My Posh: `rake ohmyposh:update`
- Reload tmux config in all sessions: `rake tmux:reload`
- Update zsh plugins: `zinit self-update && zinit update` (also run by `dfu`)
- Install the Rust toolchain: `rake rust`
- Update rustup and Rust toolchains: `rake rust:update`
- Update Homebrew packages: `rake brew:update`
- Update Python packages: `rake python:update`
- Update yt-dlp: `rake ytdlp:update`
- Update gcloud components: `rake gcloud:update`
- Uninstall asdf tool versions older than the one in use: `rake asdf:prune` (`FORCE=1` skips the confirmation prompt)
- Preview which asdf tool versions would be pruned: `rake asdf:prune_preview`

## Code Style Guidelines

- Ruby: Follow Rubocop guidelines in `./rubocop/rubocop.yml`
- Line length limit: 160 characters
- Indentation: 2 spaces
- Prefer single quotes for strings unless interpolation is needed
- Use snake_case for methods and variables
- Use frozen_string_literal pragmas in Ruby files
- Shell scripts should use proper error handling
- Document rake tasks with descriptions
- Method naming: Use descriptive names that reflect functionality
- File organization: Group related files by tool/function in separate directories

## AeroSpace Configuration

- A tiling window manager that uses the tree paradigm made popular by the [i3 window manager](https://i3wm.org/)
- Located in `.config/aerospace` following XDG directory structure
- Uses a TOML format for configuration
- The guide for how to configure AeroSpace can be found [here](https://nikitabobko.github.io/AeroSpace/guide)
- The Github project for AeroSpace can be found [here](https://github.com/nikitabobko/AeroSpace)

## Tmux Configuration

- Deployed to `~/.config/tmux` following XDG directory structure (the repo's `./tmux/` dir is symlinked there)
- Main configuration in `tmux.conf`, theme in `theme.conf`
- Uses TPM (Tmux Plugin Manager) for plugins, installed to `~/.config/tmux/plugins/`
- VHS Era theme with powerline-style status bar segments and double-arrow separators
- Custom helper scripts (e.g., `git-aware-popup.sh`) live in the `./tmux/` directory
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
- Updates are delayed by first-observed timestamps: `./nvim/pins.json` is authoritative (GENERATED — never hand-edit); `./nvim/nvim-pack-lock.json` is vim.pack's derived lockfile; both must agree and travel in one commit (`rake nvim:commit` enforces consistency)
- Update machinery: `./nvim/lua/pack/` (delay.lua pure core, gitops.lua git layer, loader.lua) + `./nvim/scripts/update.lua`; tests in `./nvim/tests/*_spec.lua`
- The updater MUST run with `-u NONE` — init.lua pre-registering vim.pack specs would freeze update targets (re-adds are no-ops)
- A plugin spec with no pin entry is a hard startup error; `rake nvim:update` is the only path that creates pins (never fall back to branch tips)
- Adding a plugin: new spec file, then `rake nvim:update` to bootstrap its delayed pin; removing: delete the spec file, then clean up pin/lockfile entries and the on-disk clone
- Plugin-bound keymaps live in that plugin's spec file; global keymaps in `./nvim/lua/config/keymaps.lua`; autocmds in `./nvim/lua/config/autocmds.lua`; which-key groups in `./nvim/lua/plugins/which-key.lua`
- nvim-treesitter pins the `main` branch (post-rewrite API — no module system); endwise and contextindent carry commented compat shims in their spec files; lspconfig.lua uses one pcall-guarded internal mason-lspconfig API (check on its pin bumps)
- Mason packages are NOT tracked by the repo, so dropping a tool/LSP from config leaves orphans on every other machine; `rake nvim:mason_prune` reconciles them (runs as the last step of `nvim:update`). The authoritative "keep" set is assembled at runtime: `mason.lua`'s `ensure_installed` plus the Mason packages backing enabled servers in `lspconfig.lua`, both registered into `./nvim/lua/pack/mason_desired.lua` from their `config()`. The prune script (`./nvim/scripts/mason_prune.lua`) loads the FULL config (NOT `-u NONE`, unlike the updater) and refuses to run if any source failed to register (guards against over-deletion on a startup error)
- Lua: stylua format (2-space indent, 120 column width); requires Neovim 0.12+; updater needs `jq` and `git`

## Zsh Configuration

- Organized using XDG directory structure with configs in `.config/zsh`
- Zsh files are modular and stored in `./zsh/zshrc.d/` directory
- Using `zdharma-continuum/zinit` for zsh plugin support
- Custom functions go in `./zsh/functions/` directory with one function per file
- Custom completions go in `completions/` directory following zsh-completions format
- Aliases go in the `./zsh/zshrc.d/04-aliases.zsh` file
- Naming convention for zshrc.d files: numeric prefix for load order (e.g., `02-functions.zsh`) (but only if load order is strictly required)
- Global aliases use suffix format (e.g., `alias -g G='| grep -E'`)
- History settings: large history size, ignore duplicates, share across sessions
- Use descriptive comments for functions and aliases
- Follow existing patterns for tool-specific configurations (each tool has its own file)
- NEVER recommend the forgit zsh plugin -- I hate it
- Machine identity lives in `zshrc.d/machine.zsh`: `DOTFILES_MACHINE` (gcw vs
  other, detected from `/etc/workstation-startup.d`) and `WORK_MACHINE`, which is
  exported from the `~/.work_machine` flag file. That file is the source of truth
  for work-vs-personal — repo code tests the file (`work_machine?` in the
  Rakefile, `[ -f ]` in shell), never the exported variable, so the answer is the
  same in tmux popups, cron and other detached contexts. `touch` to enable, `rm`
  to disable; it is machine-local and nothing in the repo manages it

## Git Configuration

- Located in `.config/git` following XDG directory structure
- Main configuration in `config` file with local overrides in `local` file
- Use descriptive git aliases that enhance workflow speed
- Git hooks stored in `hooks/` directory (pre-push hook prevents pushing fixup commits)
- GitHub CLI configuration in `gh/config.yml` with helpful aliases
- GitHub Dashboard config in `gh-dash/config.yml` for PR management, with
  `gh-dash/config-work.yml` as a work-machine overlay (`include`s the base
  config, replaces `prSections` with `org:persona-id`-scoped ones);
  `gh-dash/gh-dash.sh` selects between them on the `~/.work_machine` flag and
  is what tmux `prefix + h` and the `ghd` alias invoke
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
- Managed via Homebrew with update checks in rake tasks

## Claude Configuration

- Located in `.config/claude` following XDG directory structure
- Global memory file stored in `.config/claude/CLAUDE.md` for persistent context across Claude Code sessions
- Memory file maintains important context, preferences, and recurring tasks
- Structure memory file with clear section headers and descriptive content
- Memory file content should be concise and focused on high-value information
- Never include project-specific terminology, conventions, and preferences in the global memory file — those belong in the project's CLAUDE.md
- Document complex workflows that should be remembered across sessions
- Skills dividing line: skills for working *on this repo* (e.g., `managing-nvim-plugins`) go in `.claude/skills/` (project-scoped, only loaded in this repo); skills wanted in every session everywhere (e.g., `morning-startup`, `daily-wrap`) go in `claude/skills/` (symlinked to `~/.claude/skills`, global)
- `~/.claude/settings.json` is seeded by `home/dot_claude/create_private_settings.json` and then never touched again (`create_` = write if absent). It is not tracked — it's live, per-machine state (includes work-specific persona/allowedTools config on work machines) and must never be committed. `claude/settings.skeleton.json` is the tracked, curated set of portable defaults everyone should start from. Use the `claude-settings` skill (`promote`/`apply`) to move changes between the two: `promote` lifts a general-purpose improvement out of the live `settings.json` into the tracked skeleton; `apply` layers the skeleton's defaults onto a live `settings.json` that's drifted behind it

## Rust Configuration

- Managed by `rustup` (the canonical Linux/macOS installer), not Homebrew or apt
- Rake tasks in `rust/rust.rake`; shell integration in `zsh/zshrc.d/rust.zsh`
- Installed with `--no-modify-path` so the installer never edits the managed `.zshrc`; `rust.zsh` sources `~/.cargo/env` instead to put `~/.cargo/bin` on PATH
- `rake rust:install` is idempotent — it detects an existing rustup (on PATH or in `~/.cargo/bin`) and skips the installer
- Removing the toolchain is deliberately never automatic; use the explicit `rake rust:uninstall`
- `asdf:asdf` depends on `rust:install`: ruby-build only compiles YJIT/ZJIT into Ruby when a Rust toolchain exists at build time

