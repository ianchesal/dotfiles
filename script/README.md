# dotfiles/script

Helper scripts that support the dotfiles, run directly or wired up by rake
tasks defined elsewhere in the repo.

## Layout

```
gen-claude-completions  Generates zsh/completions/_claude from `claude --help`
```

`gen-claude-completions` is a Ruby script that parses `claude --help` and writes
a zsh completion spec to `zsh/completions/_claude`. Run it directly or via
`rake claude:gen_completions`; the generated file carries a "do not edit by
hand" header.
