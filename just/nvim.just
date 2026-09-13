set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# nvim/ deliberately stays outside the chezmoi source state: ~/.config/nvim is a
# symlink_ entry pointing back here, so editing a plugin spec is instantly live.

# Update nvim plugins (30-day delayed) and Mason packages
update: plugin-update mason-prune

[private]
plugin-update:
    #!/usr/bin/env bash
    set -euo pipefail
    # These files get big. Nuke them regularly.
    for logfile in lsp.log noice.log mason.log conform.log log; do
      rm -f "$HOME/.local/state/nvim/$logfile"
    done
    # -u NONE is load-bearing: init.lua must not pre-register vim.pack specs
    # (re-adds are no-ops and would freeze update targets at startup pins).
    nvim --headless -u NONE -l "$REPO/nvim/scripts/update.lua"
    # Parity with the old task: MasonUpdate refreshes the registry only, not
    # installed packages (those need MasonUpdateAll + its completion autocmd).
    nvim --headless "+MasonUpdate" +qa

# Preview which plugin updates are eligible, without applying them
outdated:
    @nvim --headless -u NONE -l "$REPO/nvim/scripts/update.lua" --dry-run

# Check for and commit nvim dependency updates
commit:
    @"$REPO/script/nvim-commit"

# Remove on-disk plugin clones not in pins.json (sync after pulling deletions)
prune:
    #!/usr/bin/env bash
    set -euo pipefail
    pack_dir=$HOME/.local/share/nvim/site/pack/core/opt
    [ -d "$pack_dir" ] || { printf '\033[32m%s\033[0m\n' 'No plugin directory to prune'; exit 0; }
    authorized=$(jq -r '.plugins | keys[]' "$REPO/nvim/pins.json")
    orphans=$(
      find "$pack_dir" -mindepth 1 -maxdepth 1 -not -name '.*' -exec basename {} \; |
        grep -vxF "$authorized" || true
    )
    if [ -z "$orphans" ]; then
      printf '\033[32m%s\033[0m\n' 'No orphaned plugins found'
      exit 0
    fi
    printf '\033[33mRemoving orphaned plugins: %s\033[0m\n' "$(printf '%s' "$orphans" | paste -sd, - | sed 's/,/, /g')"
    list=$(printf "%s\n" "$orphans" | sed "s/.*/'&'/" | paste -sd, - | sed 's/,/, /g')
    nvim --headless -u NONE "+lua vim.pack.del({ $list })" +qa
    printf '\033[32m%s\033[0m\n' 'Done'

# nvim --headless writes to stderr and drops the final newline, so its last line
# runs into whatever the fan-out prints next. The trailing printf restores it;
# it stays a separate statement so a failing nvim still fails the recipe.

# Remove Mason packages no longer wanted by the config
mason-prune:
    #!/usr/bin/env bash
    set -euo pipefail
    nvim --headless -c "luafile $REPO/nvim/scripts/mason_prune.lua" -c qa
    printf '\n' >&2

# Preview which Mason packages would be pruned, without removing them
mason-outdated:
    #!/usr/bin/env bash
    set -euo pipefail
    nvim --headless -c 'lua _G.MASON_PRUNE_DRY = true' \
      -c "luafile $REPO/nvim/scripts/mason_prune.lua" -c qa
    printf '\n' >&2

# Run the nvim machinery tests (delay, gitops, loader)
test:
    #!/usr/bin/env bash
    set -euo pipefail
    for spec in "$REPO"/nvim/tests/*_spec.lua; do
      echo "nvim: ${spec##*/}"
      nvim --headless -u NONE -l "$spec"
    done
