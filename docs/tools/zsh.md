# dotfiles/zsh

Zsh configuration organized under the XDG directory structure, with
[zinit](https://github.com/zdharma-continuum/zinit) as the plugin manager. The
layout is modeled on [getantidote/zdotdir](https://github.com/getantidote/zdotdir)
— everything lives under `$ZDOTDIR` (`~/.config/zsh`) and the only file placed in
`$HOME` is `.zshenv`, which bootstraps that directory.

It exists because oh-my-zsh was too slow opening new tabs in Kitty; this config
is a leaner rebuild around zinit's lazy loading.

## Layout

```
.zshenv                  Sourced for EVERY shell; sets XDG basedirs + ZDOTDIR. The
                         one file symlinked into $HOME (~/.zshenv).
.zprofile                Login shells: BROWSER/EDITOR/PAGER, locale, $PATH, less opts
.zshrc                   Interactive shells: Homebrew shellenv, zinit + plugins,
                         compinit, oh-my-posh, then sources zshrc.d/*.zsh
zshrc.d/*.zsh            Modular config, sourced in filename order (see below)
functions/               Autoloaded functions, one per file (cdf, nv, tailf, …)
completions/             Custom completions in zsh-completions format (_claude, …)
.zprofile / .zshenv      (deployed via symlink; see Tasks)
zsh.rake                 Install / update / clean tasks
```

## Load order

Zsh sources files in this sequence; understanding it tells you where new config
belongs:

1. **`.zshenv`** — read by *all* shells (interactive or not, login or not). Sets
   the XDG basedirs and `ZDOTDIR=$XDG_CONFIG_HOME/zsh` so the rest of the config
   can be found. Keep this minimal — it runs for every script invocation.
2. **`.zprofile`** — read by *login* shells only. Exports `BROWSER`/`EDITOR`/
   `PAGER`, locale, the base `$PATH` array, and `less` options.
3. **`.zshrc`** — read by *interactive* shells. Detects Homebrew, bootstraps zinit
   (auto-cloning it on first run), loads plugins and Oh My Zsh snippets, runs
   `compinit`, initializes Oh My Posh, then sources every `zshrc.d/*.zsh` in
   sorted order, and finally `~/.zsh_local` and `~/.secrets` if present.

Inside `zshrc.d/`, files are sourced in glob (alphanumeric) order, and any file
whose name begins with `~` is skipped. The numeric and `z`-prefixes pin the few
files whose load order actually matters:

```
01-history-hook.zsh      First
02-functions.zsh         Adds functions/ to fpath and autoloads it
03-env.zsh               EDITOR, history options, extra $PATH entries
04-aliases.zsh           Aliases (regular and global)
<tool>.zsh               Per-tool config, alphabetical (asdf, fzf, kitty, python, …)
zz-vim-mode.zsh          Near the end
zzz-history-search.zsh   Last
```

## Where to add things

- **An alias** → `zshrc.d/04-aliases.zsh`. Global aliases use the suffix form
  (`alias -g G='| grep -E'`).
- **A custom function** → a new file in `functions/`, one function per file
  (the filename is the function name; it's autoloaded by `02-functions.zsh`).
- **A custom completion** → a `_name` file in `completions/`, in
  zsh-completions format. The directory is already on `fpath`.
- **Config for a specific tool** → its own `zshrc.d/<tool>.zsh` file. Only add a
  numeric prefix if load order is strictly required; otherwise let it fall in
  alphabetically.
- **An environment variable for every shell** (including scripts) → `.zshenv`.
  Login-shell-only env or `$PATH` setup → `.zprofile` or `03-env.zsh`.
- **A plugin** → add a `zinit light <owner/repo>` line in `.zshrc` alongside the
  others. (Do not suggest the forgit plugin.)

## Tasks

- `rake zsh` — install: symlink `~/.config/zsh` → this directory and `~/.zshenv`, and create the needed cache/data dirs
- `rake zsh:update` — update zsh and plugins (currently a TODO no-op)
- `rake clean` — restore `~/.zshenv` and remove the zsh symlinks

## Debugging startup time

1. Add `zmodload zsh/zprof` to the top of `.zshrc` (a commented stub is already there).
2. Measure: `time zsh -i -c exit`.
3. Uncomment the trailing `zprof` line to see the per-function profile.
