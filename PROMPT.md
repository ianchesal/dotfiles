# PROMPT.md

This file provides guidance to AI agents working on this repository.

## Build/Test/Lint Commands

- Install dotfiles: `rake all`
- Install specific configuration: `rake <tool>` (e.g., `rake tmux`, `rake nvim`, `rake zsh`, `rake git`, `rake kitty`, `rake ohmyposh`)
- Remove customizations: `rake clean`
- List all rake tasks: `rake -T`
- Run Rubocop checks: `rake rubocop:check`
- Auto-correct Rubocop issues: `rake rubocop:auto_correct`
- Update configurations: `rake update`
- Update Neovim plugins: `rake nvim:update`
- Check and commit Neovim dependency updates: `rake nvim:commit`
- Check for Oh My Posh updates: `rake ohmyposh:check_update`
- Update Oh My Posh: `rake ohmyposh:update`

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

## Neovim Configuration

- Based on [LazyVim](https://www.lazyvim.org/) with custom plugins and configurations
- Some LazyVim features are enabled via the `./nvim/lazyvim.json`
- Lua files should follow stylua.toml format (2 space indent, 120 column width)
- Plugin configuration belongs in `./nvim/lua/plugins/*.lua` files
- Custom keymaps should be defined in `./nvim/lua/config/keymaps.lua`
- Custom autocmd config should be defined in `./nvim/lua/config/autocmds.lua`
- Use which-key for documenting keybindings with descriptive labels
- Respect existing plugin organization and structure
- Requires Neovim 0.10+ for compatibility

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
- Custom Tokyo Night theme with defined color palette
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
- Never include project-specific terminology, conventions, and preferences. Project-specific things should go in a PROMPT.md file in the root of the project.
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
