# dotfiles/asdf

[asdf](https://asdf-vm.com/) runtime version manager configuration. Installs
the asdf plugins and tool versions used across machines, and symlinks the asdf
runtime config.

## Layout

```
asdf.rake           Install/update/clean rake tasks
asdfrc              Symlinked to ~/.asdfrc (enables legacy_version_file)
tool-versions       Symlinked to ~/.tool-versions (pinned runtime versions)
reinstall-ruby.sh   Rebuilds asdf Ruby to fix broken psych/libyaml linkage
```

Managed plugins: `ruby`, `nodejs`, `terraform`, `golang`, `packer`, `rust`.

## Tasks

- `rake asdf` — install all asdf dotfiles (symlink config, add plugins, install runtimes)
- `rake asdf:update` — update all asdf plugins (`asdf plugin update --all`)

## reinstall-ruby.sh

Recovery script that uninstalls and rebuilds the asdf Ruby from `tool-versions`
with the libyaml rpath baked in, fixing broken `psych`/libyaml linkage. It
snapshots the installed gem list first (uninstalling Ruby deletes its gems) and
offers to reinstall them at the end.

```
./reinstall-ruby.sh           # interactive (prompts before destructive steps)
./reinstall-ruby.sh --yes     # no prompts (assume yes)
```

Requires `asdf` on PATH and libyaml installed (`brew install libyaml`).
