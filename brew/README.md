# dotfiles/brew

[Homebrew](https://brew.sh/) package configuration. The `Brewfile` declares the
formulae installed on every machine; the install script bootstraps Homebrew and
runs `brew bundle`.

## Layout

```
../just/brew.just   Update and trust recipes
../script/brew-trust  Applies `trusted` (shared by the recipe and the bootstrap)
Brewfile            Declared taps, formulae and casks (installed via `brew bundle`)
trusted             Third-party taps/formulae this repo trusts (see below)
brew-install.sh     Installs Homebrew, sets up PATH, trusts, runs `brew bundle`
```

## Install

Run `./brew-install.sh` to install Homebrew, detect its location (macOS Apple
Silicon, macOS Intel, or Linuxbrew), apply the trust list, and install
everything in the `Brewfile`.

On a normal `chezmoi init --apply` bootstrap this happens automatically via
`home/run_once_before_20-brew-bundle.sh`, which does the same three steps.

## Trusting third-party taps

Homebrew 7 refuses to load a formula or cask from a non-official tap until that
tap has been trusted — a formula is arbitrary Ruby that brew executes, so this
is a supply-chain guard. An untrusted tap fails with a misleading
`invalid syntax in tap` error.

The trust store is **machine-local** (`~/.config/homebrew/trust.json` under a
set `XDG_CONFIG_HOME`, `~/.homebrew/trust.json` otherwise) and chezmoi does not
manage it, so a fresh machine starts with an empty store. `trusted` is this
repo's declared, reviewed list; `just brew::trust` applies it, and both
bootstrap paths run it before `brew bundle`.

Adding a third-party tap to the `Brewfile` means adding a matching entry to
`trusted`, otherwise the next fresh machine fails to bootstrap. Prefer a
`formula` or `cask` entry over a `tap` entry: a tap grant covers everything in
that repo now and in every future commit, while a formula grant covers only the
one thing actually installed. `just doctor` reports any declared entry that is
not trusted on the current machine.

## Tasks

- `just brew::update` — update Homebrew-installed packages
- `just brew::trust` — trust the third-party entries declared in `trusted`

The update task upgrades only outdated formulae, skipping pinned packages and
`oh-my-posh` (the latter is managed separately via the `ohmyposh` tasks).
