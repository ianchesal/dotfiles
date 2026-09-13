# dotfiles/brew

[Homebrew](https://brew.sh/) package configuration. The `Brewfile` declares the
formulae installed on every machine; the install script bootstraps Homebrew and
runs `brew bundle`.

## Layout

```
../just/brew.just Update recipe
Brewfile          Declared taps and formulae (installed via `brew bundle`)
brew-install.sh   Installs Homebrew, sets up PATH, runs `brew bundle`
```

## Install

Run `./brew-install.sh` to install Homebrew, detect its location (macOS Apple
Silicon, macOS Intel, or Linuxbrew), and install everything in the `Brewfile`.

## Tasks

- `just brew::update` — update Homebrew-installed packages

The update task upgrades only outdated formulae, skipping pinned packages and
`oh-my-posh` (the latter is managed separately via the `ohmyposh` tasks).
