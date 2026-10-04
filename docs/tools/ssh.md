# SSH

Keys live in 1Password; config comes from this repo plus 1Password.

## Pieces

| What | Where | Managed by |
|---|---|---|
| Private keys | 1Password, Private vault, SSH Key items | 1Password only |
| `~/.ssh/config` (LAN hosts, GitHub, agent) | `home/private_dot_ssh/private_config` | chezmoi |
| Public keys `~/.ssh/*.pub` | `home/private_dot_ssh/*.pub` | chezmoi |
| `~/.ssh/config.d/<title>` (public-IP hosts) | Secure Notes tagged `ssh-config` | `just ssh::sync` |
| `~/.1password/agent.sock` | native (Linux), symlink (macOS), relay (WSL) | 1Password / chezmoi / `zshrc.d/1password.zsh` |
| `known_hosts`, `authorized_keys` | the machine | nobody |

Work machines and the cloud workstation get none of this (`home/.chezmoiignore`).

## Adding a host

- **LAN host:** add a block to `home/private_dot_ssh/private_config`; key auth
  pins `IdentityFile ~/.ssh/<name>.pub` + `IdentitiesOnly yes`, password auth
  sets `PubkeyAuthentication no`. `chezmoi apply ~/.ssh`.
- **Anything with a public IP:** create a Secure Note in Private, title = file
  name (letters, digits, `.`, `_`, `-`; must start with a letter or digit), tag
  `ssh-config`, body = the `Host` block. `just ssh::sync`.

## Adding a key

Generate or import it in the 1Password app (the CLI cannot import). Export the
public half into the repo:

    op item get '<item title>' --vault Private --fields 'public key' > home/private_dot_ssh/<name>.pub

## New machine

1. Install 1Password, enable *Settings → Developer → Use the SSH agent* (and CLI
   integration on macOS).
2. WSL only: `winget install albertony.npiperelay`; stop and disable the Windows
   *OpenSSH Authentication Agent* service; open a new shell.
3. `ssh-add -l` lists the 1Password keys.
4. `chezmoi apply`, then `just ssh::sync` (at the console on macOS — over SSH it
   skips, because the 1Password prompt would appear on the Mac's display).

## Troubleshooting

- `just ssh::sync` says not signed in: on WSL `eval "$(op signin)"`; on macOS
  unlock the app.
- `Permission denied (publickey)`: `ssh -G <host> | grep -E 'identity(file|agent)'`
  and `ssh-add -l`. No `identityagent` line means the socket is missing — on WSL,
  open a new shell to restart the relay, and check `just doctor`.
- `Too many authentication failures`: the host is not pinned; add
  `IdentityFile` + `IdentitiesOnly yes`.
