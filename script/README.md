# dotfiles/script

Helper scripts that support the dotfiles, run directly or wired up by rake
tasks defined elsewhere in the repo.

## Layout

```
bootstrap               Symlinks the bare-minimum configs into a Coder/Codespaces workspace
gen-claude-completions  Generates zsh/completions/_claude from `claude --help`
```

`bootstrap` follows the [Codespaces
dotfiles](https://docs.github.com/en/codespaces/setting-your-user-preferences/personalizing-github-codespaces-for-your-account#dotfiles)
convention: it creates the XDG base directories and symlinks just the configs
needed in a remote [Coder](https://coder.com) workspace (asdf, gh, gh-dash,
nvim, ripgrep, tmux). The zsh setup is intentionally left out for now.

`gen-claude-completions` is a Ruby script that parses `claude --help` and writes
a zsh completion spec to `zsh/completions/_claude`. Run it directly or via
`rake claude:gen_completions`; the generated file carries a "do not edit by
hand" header.
