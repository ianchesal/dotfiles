# Dotfiles

This file provides guidance to AI agents working on this repository.

## Target Platforms

- macOS (zsh/Kitty), Debian Linux, and WSL2
- Changes should be portable across all three unless explicitly platform-specific

## Build/Test/Lint Commands

- Install dotfiles: `rake all`
- Install specific configuration: `rake <tool>` (e.g., `rake tmux`, `rake nvim`, `rake zsh`, `rake git`, `rake kitty`, `rake ohmyposh`)
- Remove customizations: `rake clean`
- List all rake tasks: `rake -T`
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
- Update zsh and plugins: `rake zsh:update`
- Update Homebrew packages: `rake brew:update`
- Update Python packages: `rake python:update`
- Update yt-dlp: `rake ytdlp:update`
- Update gcloud components: `rake gcloud:update`

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

## Git Configuration

- Located in `.config/git` following XDG directory structure
- Main configuration in `config` file with local overrides in `local` file
- Use descriptive git aliases that enhance workflow speed
- Git hooks stored in `hooks/` directory (pre-push hook prevents pushing fixup commits)
- GitHub CLI configuration in `gh/config.yml` with helpful aliases
- GitHub Dashboard config in `gh-dash/config.yml` for PR management
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

## OpenCode Configuration

- Located in `.config/opencode` following XDG directory structure
- Configuration managed via `opencode.json` with schema validation from https://opencode.ai/config.json
- Includes comprehensive agent instructions in `AGENTS.md` for structured problem-solving workflow
- Agent workflow follows Think → Plan → Iterate → Execute phases for collaborative development
- Rake tasks available for installation (`rake opencode`), updates (`rake opencode:update`), and cleanup (`rake opencode:clean`)
- CLI managed via npm with global installation to `~/.npm-global/bin/opencode`
- Supports upgrade functionality through the opencode CLI
- Configuration includes security guidelines, development practices, and file operation preferences
