# dotfiles/gem

RubyGems configuration. Symlinks the gem RC file and provides tasks to update
bundled gems and reconcile gem-version conflicts.

## Layout

```
gem.rake   Install/cleanup/update/clean rake tasks
gemrc      Symlinked to ~/.gemrc (skips rdoc/ri on install and update)
```

## Tasks

- `rake gem` — install all gem-related dotfiles (create `~/.gem`, symlink `~/.gemrc`)
- `rake gem:cleanup` — remove old gem versions and uninstall default-gem conflicts
- `rake gem:update` — update bundled gems (`bundle update`) and clean up gem conflicts

## Notes

- `gem:cleanup` removes versions that conflict with Ruby's bundled default gems
  (the source of "Unresolved or ambiguous specs" warnings), but skips any
  version pinned in a `Gemfile.lock`.
- `gem:cleanup` is skipped when the `WORK_MACHINE` environment variable is set.
