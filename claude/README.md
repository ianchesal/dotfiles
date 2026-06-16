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
claude.rake              install / update / clean / completion tasks
commands/                Custom slash commands
skills/                  Custom skills
plugins/                 Installed plugins
```

Runtime state directories (`projects/`, `sessions/`, `tasks/`, `file-history/`,
`backups/`, credentials, history, etc.) are created by the CLI and are not
hand-maintained config.

## Tasks

- `rake claude` — install: symlink `~/.claude`, run the official installer, fix `~/.claude.json` permissions
- `rake claude:update` — fix permissions, then run `claude update`; regenerates zsh completions if the version changed
- `rake claude:gen_completions` — regenerate `zsh/completions/_claude` from `claude --help`
- `rake claude:clean` — remove the `~/.claude` symlink, the `claude` binary, and `~/.local/share/claude`

## Notes

- `rake claude:permissions` chmods `~/.claude.json` to `600` so credentials are not world-readable.
- The global memory file (`CLAUDE.md`) should hold concise, high-value context and preferences only — never project-specific terminology or secrets.
