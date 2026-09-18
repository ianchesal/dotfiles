# dotfiles/claude

Configuration for [Claude Code](https://claude.ai), Anthropic's official CLI
agent. chezmoi copies `home/dot_claude/` to `~/.claude` — deliberately not under
`.config/`, because Claude Code does not honour XDG for its own directory. So
commands, skills, plugins, and the global memory file travel with the repo, but
they are **copies**: an edit here is not live until the next `chezmoi apply`. The CLI itself
is installed via the official installer (`curl -fsSL https://claude.ai/install.sh | bash`),
not Homebrew.

## Layout

```
CLAUDE.md                     Global memory file (persistent context/preferences across sessions)
create_private_settings.json  Seeds ~/.claude/settings.json once, then never touches it again
keybindings.json              Custom key bindings
executable_statusline-command.sh  Script that renders the custom status line
commands/                     Custom slash commands
skills/                       Global skills (repo-scoped ones live in .claude/skills/)
plugins/                      Installed plugins
```

Source names carry chezmoi prefixes: `create_` writes only if the target is
absent, `executable_` sets the exec bit. The live `~/.claude/settings.json` is
**not** tracked — it is per-machine state, and on work machines carries
persona/`allowedTools` config that must never be committed. Hand-edit the seed;
never `chezmoi re-add` the live file.

Runtime state directories (`projects/`, `sessions/`, `tasks/`, `file-history/`,
`backups/`, credentials, history, etc.) are created by the CLI and are not
hand-maintained config.

## Tasks

- `just claude::install` — run the official installer, unless apt already owns `claude-code`
- `just claude::update` — fix permissions, then run `claude update`; regenerates zsh completions if the version changed, and seeds them if missing
- `just claude::gen-completions` — regenerate `~/.config/zsh/completions/_claude` directly (not chezmoi-managed) from `claude --help`
  (`script/gen-claude-completions.py --if-missing` no-ops when a spec is already there — how `claude::update` seeds a fresh machine)

## Notes

- `just claude::permissions` chmods `~/.claude.json` to `600` so credentials are not world-readable. `claude::update` depends on it, so it runs on every update.
- The global memory file (`CLAUDE.md`) should hold concise, high-value context and preferences only — never project-specific terminology or secrets.
- The zsh completion spec is **not** in the chezmoi source state. It is generated
  from the locally installed `claude --version`, so it is machine-local; see
  `script/README.md` for why tracking it was wrong.
