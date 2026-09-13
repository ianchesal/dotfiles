set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# Remove old gem versions and uninstall default-gem conflicts
cleanup:
    @"$REPO/script/gem-cleanup"
