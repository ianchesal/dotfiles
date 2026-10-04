set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# The fonts every machine should have, as Homebrew cask names. To add a font,
# find its cask with `brew search --cask font-<name>` and append it here. Stick
# to casks from the official homebrew/cask repo: a third-party tap would also
# need a brew/trusted entry. script/fonts-install does the work, including the
# macOS quarantine fix that lets Font Book see them.
fonts := "font-jetbrains-mono-nerd-font font-noto-sans"

# Install the fonts this repo expects (on macOS, also unquarantine them so Font Book sees them)
install:
    @"$REPO/script/fonts-install" {{ fonts }}
