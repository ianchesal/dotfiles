# dotfiles/rubocop

[RuboCop](https://github.com/rubocop/rubocop) configuration. Symlinks the global
RuboCop config and provides tasks to lint and auto-correct this repo's Ruby
(currently the `Rakefile`).

## Layout

```
rubocop.rake   Install/check/auto_correct/clean rake tasks
rubocop.yml    Symlinked to ~/.rubocop.yml
```

Key style: 160-character line length; `Metrics/ClassLength` and
`Metrics/MethodLength` disabled.

## Tasks

- `rake rubocop` — install RuboCop dotfiles (symlink `~/.rubocop.yml`)
- `rake rubocop:check` — run RuboCop checks
- `rake rubocop:auto_correct` — auto-correct RuboCop failures
