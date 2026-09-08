# dotfiles/git

Git configuration following the XDG directory structure. The repo's `git/`
directory is symlinked to `~/.config/git`, with companion configs for the
GitHub CLI (`gh`) and the GitHub Dashboard TUI (`gh-dash`). The workflow leans
on a rebase-by-default setup and a large set of custom aliases.

## Layout

```
config                   Main git config: aliases, delta pager, rebase workflow
local                    Machine-local overrides (e.g. work email) via [include]
ignore                   Global gitignore patterns
hooks/pre-push           Blocks pushing commits whose subject starts with "fixup!"
templates/               init.templatedir contents seeded into new repos
gh/config.yml            GitHub CLI config and aliases (co, prs, l)
gh/hosts.yml             gh host/auth state (machine-local)
gh-dash/config.yml       Default gh-dash sections and repo path mappings
gh-dash/config-work.yml  Work overlay: org-scoped my-PRs and assigned sections
gh-dash/gh-dash.sh       Launcher that picks the config for this machine
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
- gh-dash is launched through `gh-dash/gh-dash.sh` (bound to tmux `prefix + h`
  and aliased to `ghd`). When `WORK_MACHINE=true` it passes `--config
  config-work.yml`, which `include`s `config.yml` and replaces `prSections`
  with org-scoped ones: "My Pull Requests" (`org:persona-id author:@me`) and
  "Assigned to Me" (`org:persona-id assignee:@me -author:@me`). GitHub search
  has no `OR`, so author-or-assignee has to be two sections. Anywhere else,
  `gh dash` finds `config.yml` on its own and "My Pull Requests" is just
  `author:@me` across all repos.
- The Dependabot section is scoped to `org:persona-id org:datenight-team
  user:ianchesal`. Repeated `org:`/`user:` qualifiers OR together in GitHub
  search (`author:`/`assignee:` do not), and `ianchesal` is a user account, so
  it takes `user:` rather than `org:`.
- Section filters omit `is:pr` — gh-dash always prepends it for PR sections,
  and repeating it renders as `is:pr is:pr` in the search bar.
- Both configs set `smartFilteringAtLaunch: false`. Left on (the gh-dash
  default), it injects `repo:<current repo>` into every section lacking an
  explicit `repo:`, which scoped the whole dashboard to whichever clone the
  popup opened from. Press `S` inside the dashboard to scope to a repo on
  demand.

## Tasks

- `rake git` — install git dotfiles (symlinks + gh extension setup)
- `rake git:update` — upgrade installed `gh` CLI extensions
