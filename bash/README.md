# dotfiles/bash

Bash configuration, used mainly at work (zsh is the daily driver at home).
Provides shell bootstrap, history/completion tuning, git aliases, and a couple
of self-contained prompt themes lifted from
[bash-it](https://github.com/revans/bash-it).

## Layout

```
bash_profile        Login shell bootstrap: EDITOR, PATH, asdf shims, sources aliases + themes
bashrc              History (size/dedup), checkwinsize, PATH helpers
inputrc             readline: history-search on up/down, case-insensitive completion, no bell
aliases             Large set of git aliases plus ls/rsync/docker helpers and an rpg() function
colors.theme.bash   ANSI/tput color helpers (sourced by the prompt themes)
base.theme.bash     SCM (git/hg/svn) prompt-info functions
ianc.theme.bash     Custom PROMPT_COMMAND prompt
pure.theme.bash     Minimalist git-aware prompt (currently sourced by bash_profile)
```

## Tasks

- `rake bash` — install (symlink) the bash dotfiles (`.inputrc`, `.bash_profile`)
- `rake clean` — restore the original `.bashrc`, `.inputrc`, `.bash_profile`

## Notes

- `bash_profile` sources `~/.bash_local` and `~/.secrets` if present for
  machine-local and secret config (never checked in).
- Themes are independent; `bash_profile` currently sources `colors` + `pure`.
