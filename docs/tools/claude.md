# dotfiles/claude

Configuration for [Claude Code](https://claude.ai), Anthropic's official CLI
agent. The whole directory is symlinked to `~/.claude`, so settings, commands,
skills, plugins, and the global memory file travel with the repo. The CLI itself
is installed via the official installer (`curl -fsSL https://claude.ai/install.sh | bash`),
not Homebrew.

## Layout

```
CLAUDE.md                Global memory file (persistent context/preferences across sessions)
settings.json            Claude Code settings (permissions, hooks, env)
keybindings.json         Custom key bindings
statusline-command.sh    Script that renders the custom status line
commands/                Custom slash commands
skills/                  Custom skills
plugins/                 Installed plugins
```

Runtime state directories (`projects/`, `sessions/`, `tasks/`, `file-history/`,
`backups/`, credentials, history, etc.) are created by the CLI and are not
hand-maintained config.

## Tasks

- `just claude::install` — run the official installer, unless apt already owns `claude-code`
- `just claude::update` — fix permissions, then run `claude update`; regenerates zsh completions if the version changed
- `just claude::gen-completions` — regenerate `~/.config/zsh/completions/_claude` directly (not chezmoi-managed) from `claude --help`

## Notes

- `just claude::permissions` chmods `~/.claude.json` to `600` so credentials are not world-readable. `claude::update` depends on it, so it runs on every update.
- The global memory file (`CLAUDE.md`) should hold concise, high-value context and preferences only — never project-specific terminology or secrets.
