---
name: ssh-new-key
description: Use when the user wants a new SSH keypair, SSH key, or ssh key for authenticating to a host or service, stored in 1Password — "make me a new ssh key", "generate a keypair in 1password", "I need a key for <host>". Also used by ssh-new-host when a host has no key yet.
---

# New SSH Keypair in 1Password

The private half is generated inside 1Password and never touches disk. Only the
public half lands in the dotfiles repo, as `~/.ssh/<name>.pub`, where ssh config
uses it as `IdentityFile` to tell the 1Password agent which key to sign with.

## 0. Guard — stop on any failure

```bash
[ -f ~/.work_machine ] && echo STOP-work-machine
[ -d /etc/workstation-startup.d ] && echo STOP-cloud-workstation
command -v op >/dev/null || echo STOP-no-op
command -v jq >/dev/null || echo STOP-no-jq
op vault get Private --format json >/dev/null 2>&1 || echo STOP-op-signed-out
```

Any `STOP-*` line: tell the user why and do nothing else. Work machines and the
cloud workstation do not get `~/.ssh` from these dotfiles at all. Signed out:
ask them to run `! eval "$(op signin)"`, then retry.

## 1. Name and locate

- `<name>`: lowercase, `[a-z0-9][a-z0-9._-]*`, usually the host it is for
  (`homeassistant`, `github-work`). Ask if not given.
- `src=$(chezmoi source-path ~/.ssh/config)`; `dir=$(dirname "$src")`;
  `repo=$(git -C "$dir" rev-parse --show-toplevel)`. Never hardcode the repo path.
- `git -C "$repo" pull --ff-only` first. If it fails (diverged, dirty, offline),
  tell the user and stop.
- Collision check — stop and ask if either finds something:
  `op item list --vault Private --categories 'SSH Key' --format json | jq -r '.[].title' | grep -ixF <name>`
  prints a match, or `[ -e "$dir/<name>.pub" ]` is true.

## 2. Create and export

```bash
op item create --category 'SSH Key' --ssh-generate-key ed25519 --vault Private --title <name> >/dev/null
op item get <name> --vault Private --fields 'public key' > "$dir/.<name>.pub.tmp" &&
  mv "$dir/.<name>.pub.tmp" "$dir/<name>.pub" || rm -f "$dir/.<name>.pub.tmp"
```

1Password may show an approval prompt for `op` — tell the user to watch for it.

- The flag is `--ssh-generate-key` (there is no `--ssh-keytype`). Never pipe the
  item JSON to the terminal: it contains the private key.
- Use `op item get --fields`, not `op read` — `op read` references break on
  titles containing `@`.
- Check: `wc -l < "$dir/<name>.pub"` is 1 and `head -c 12` is `ssh-ed25519 `.
- If anything fails after `op item create` succeeded, the item exists: do not
  create it again (the collision check will rightly trip). Resume at the export.

## 3. Deploy, verify the agent, commit

```bash
chezmoi apply ~/.ssh/<name>.pub
ssh-keygen -lf ~/.ssh/<name>.pub      # fingerprint of the new key
ssh-add -l | grep -F "$(ssh-keygen -lf ~/.ssh/<name>.pub | awk '{print $2}')"
```

`ssh-add -l` exiting 2 means no agent is reachable at all (`SSH_AUTH_SOCK`
unset, or the WSL relay not running) — say that, it is not a key problem.
If the agent answers but the fingerprint is missing, 1Password is not
offering the key: tell the user to check the 1Password app (Settings →
Developer → SSH agent, and any `agent.toml` that restricts which vaults/items
are served). Do not continue to anything that authenticates with the key until
it shows up.

Commit only the new file: `git -C "$repo" add home/private_dot_ssh/<name>.pub`
and commit with a message like `Add <name> SSH public key`. Ask before
pushing; other machines get the `.pub` only after a push, on their next `dfu`.

## Hand-off

Report the item title, the fingerprint, and the `.pub` path. If the user wants
the key used for a host, continue with **ssh-new-host**. Do not write ssh config
here.
