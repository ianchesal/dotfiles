set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# Update all asdf plugins
update:
    @printf '\033[32m%s\033[0m\n' 'Update: asdf plugins'
    @asdf plugin update --all

# ruby-build only compiles YJIT/ZJIT into Ruby when a Rust toolchain exists at
# build time, so rust::install has to land first. A module cannot depend on a
# sibling module's recipe, hence the shell-out back through the root justfile --
# that keeps the ordering no matter how this recipe is reached.

# Add the managed plugins and install the runtimes named in ~/.tool-versions
install:
    @{{ just_executable() }} --justfile "$REPO/justfile" rust::install
    asdf plugin add ruby || true
    asdf plugin add nodejs || true
    asdf plugin add golang || true
    asdf install ruby
    asdf install nodejs
    asdf install golang

# Uninstall tool versions older than the version in use (FORCE=1 skips the prompt)
prune:
    @"$REPO/script/asdf-prune"

# Show the tool versions `just asdf::prune` would uninstall
prune-preview:
    @"$REPO/script/asdf-prune" --preview
