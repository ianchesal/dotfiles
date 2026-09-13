# gem

RubyGems configuration and the maintenance recipe that keeps a machine's
installed gems from tripping over Ruby's bundled default gems.

Nothing here is Ruby *this repo* needs — the repo has no Ruby left since the
move off Rake. It matters because Mason installs `rubocop` and `ruby-lsp` with a
plain `gem install`, and work projects are Ruby.

## Layout

```
home/dot_gemrc          Deployed by chezmoi as ~/.gemrc (skips rdoc/ri on install and update)
just/gem.just           The cleanup recipe
script/gem-cleanup      What the recipe runs
script/tests/gem-cleanup.test.sh   Tests, driven against a fake `gem`
```

## Tasks

- `just gem::cleanup` — run `gem cleanup`, then uninstall installed versions
  that duplicate a default gem

## Notes

- When both an installed version and a default version of the same gem exist,
  `Gem::Specification` emits "Unresolved or ambiguous specs" on every bundle
  run. Removing the redundant installed copy is what this clears up.
- Any version pinned in a `Gemfile.lock` anywhere in the repo is skipped, so
  bundler-managed installs are never removed. Dependency lines (indented six
  spaces) do not count as pins; only gem stanza lines (four spaces) and the
  version under `BUNDLED WITH` do.
- Skipped entirely on work machines — that is, when `~/.work_machine` exists.
