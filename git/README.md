# dotfiles/git

Git configuration following the XDG directory structure. The repo's `git/`
directory is symlinked to `~/.config/git`, with companion configs for the
GitHub CLI (`gh`) and the GitHub Dashboard TUI (`gh-dash`). The workflow leans
on a rebase-by-default setup and a large set of custom aliases.

## Layout

```
config              Main git config: aliases, delta pager, rebase workflow
local               Machine-local overrides (e.g. work email) via [include]
ignore              Global gitignore patterns
hooks/pre-push      Blocks pushing commits whose subject starts with "fixup!"
templates/          init.templatedir contents seeded into new repos
gh/config.yml       GitHub CLI config and aliases (co, prs, l)
gh/hosts.yml        gh host/auth state (machine-local)
gh-dash/config.yml  gh-dash PR dashboard sections and repo path mappings
```

## Rebase workflow

- `branch.autosetuprebase = always` — new branches rebase on pull
- `pull.ff = only` and `rebase.autosquash = true`
- `push.autoSetupRemote = true`; `init.defaultBranch = main`
- The `pre-push` hook (wired via `core.hooksPath = ~/.config/git/hooks`)
  rejects any push that still contains `fixup!` commits, so they must be
  squashed first.

## Notes

- Diffs use [delta](https://github.com/dandavison/delta) with side-by-side,
  line numbers, and decorations; `interactive.diffFilter` routes interactive
  diffs through delta too.
- `local` is pulled in via `[include] path = local` and is the place for
  per-machine overrides (the work email lives here).
- Handy aliases include `main-branch` (resolves origin's default branch),
  `com`/`track` (switch helpers), `lg`/`tree` (graph logs), and `fixup`
  (fzf-driven `--fixup` picker).
- `rake git:setup_gh` installs the `gh-f`, `gh-dash`, and `gh-stack`
  extensions when `gh` is present.

## Tasks

- `rake git` — install git dotfiles (symlinks + gh extension setup)
- `rake git:update` — upgrade installed `gh` CLI extensions
