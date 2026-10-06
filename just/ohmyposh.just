set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# Render the repo's prompt config across paths, git states and exit codes
preview:
    @"$REPO/script/ohmyposh-preview"
