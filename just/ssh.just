set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# ~/.ssh/config is chezmoi-managed and public; host blocks that must not be
# published (public IPs, ports) live in 1Password as Secure Notes tagged
# `ssh-config` and land in ~/.ssh/config.d/ via script/ssh-config-sync. The
# script skips quietly on work machines, the cloud workstation, a locked or
# signed-out 1Password, and macOS over SSH, so it is safe in the update fan-out.

# Pull ~/.ssh/config.d host blocks out of 1Password
sync:
    @"$REPO/script/ssh-config-sync"
