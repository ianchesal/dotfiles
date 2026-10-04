---
name: ssh-new-host
description: Use when the user wants to add a host, server, box, NAS, VPS or device to their ssh config — "add X to my ssh config", "set up ssh for <host>", "make <host> sshable from all my machines" — including when they give only an IP and user, or mention 1Password keys.
---

# New SSH Host, 1Password Key, Managed Everywhere

Every host gets **key auth with a 1Password key unless key auth has been tried
and shown impossible**. A missing key is not a reason for password auth — make
one. Host blocks live in the dotfiles repo (public) or in 1Password (private),
never only in the local `~/.ssh/config`.

## 0. Guard — stop on any failure

Run the same guard as **ssh-new-key** step 0 (`~/.work_machine`,
`/etc/workstation-startup.d`, `op` present and signed in). On a `STOP-*`, tell
the user and do nothing else.

Locate the repo, never hardcode it: `src=$(chezmoi source-path ~/.ssh/config)`,
`dir=$(dirname "$src")`, `repo=$(git -C "$dir" rev-parse --show-toplevel)`,
then `git -C "$repo" pull --ff-only`.

## 1. Gather

Alias, HostName, User; Port is 22 unless the user gives another. Ask for a
missing alias, HostName or User — never guess a user. For a device rather than
a server, ask what it is (it decides step 3). Refuse an alias already present:
`ssh -G <alias>` showing a `hostname` other than the alias itself, or
`grep -iEw '^[[:space:]]*Host[[:space:]].*<alias>' "$src" ~/.ssh/config.d/*`
matching (Host lines can carry several aliases).

## 2. Key

Reuse a key only if the user names one (`ls "$dir"/*.pub`). Otherwise use
**ssh-new-key** with `<name>` = the alias. Continue only once its fingerprint
appears in `ssh-add -l`.

## 3. Install the key on the host

`ssh-copy-id` needs the user's password, which you cannot type. Give the user
this line to run themselves (the `!` prefix runs it in this session):

```
! ssh-copy-id -f -i ~/.ssh/<key>.pub -p <port> -o PubkeyAuthentication=no <user>@<hostname>
```

`-f` is required: only the public half exists on disk. If the host refuses
passwords but the user already reaches it some other way, swap the trailing
`-o PubkeyAuthentication=no <user>@<hostname>` for that existing alias. Appliances
that manage `authorized_keys` in a web UI (Home Assistant add-ons, UniFi,
Synology DSM): ask the user to paste the `.pub` contents there instead.

## 4. Prove key auth

```bash
ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new \
    -o IdentitiesOnly=yes -o IdentityFile=~/.ssh/<key>.pub -p <port> <user>@<hostname> true && echo KEY-AUTH-OK
```

1Password may pop an approval prompt — tell the user to expect it.

- `KEY-AUTH-OK` → key-auth block.
- Failed → diagnose with the user (key not installed? wrong user? agent not
  offering the key?) and retry. Use a password block **only** when the user
  confirms the host cannot do key auth at all.

The block is `Host <alias>` followed by the indented options below.

| Result | Options |
|---|---|
| key auth | `HostName`, `Port` (omit if 22), `User`, `IdentityFile ~/.ssh/<key>.pub`, `IdentitiesOnly yes` |
| password only | `HostName`, `Port` (omit if 22), `User`, `PubkeyAuthentication no`, preceded by a `# password auth` comment |

Two-space indent. Never add `ForwardAgent` — that is a per-host call the user
makes by hand.

## 5. Place the block

| HostName is… | Goes to | Deploy |
|---|---|---|
| private: `10.*`, `172.16–31.*`, `192.168.*`, `*.local` | `$src`, as a new block directly above the `# 1Password's agent` comment / `Match exec` block (which must stay last) | `chezmoi apply ~/.ssh/config`, then commit `home/private_dot_ssh/private_config` (+ any new `.pub`) |
| anything else (public IP, DNS name, VPS) | 1Password Secure Note: `op item create --category 'Secure Note' --vault Private --title <alias> --tags ssh-config 'notesPlain=<block>'` | `just --justfile "$repo/justfile" ssh::sync` — nothing to commit but the `.pub` |

The repo is public, so a public address or port must never reach `$src`, a
commit message, or a PR. State which row you chose and why; the user may
override. The note title must match `[A-Za-z0-9][A-Za-z0-9._-]*`; its body is
the raw block, `Host <alias>` line included, with no header. Check it with
`op item get <alias> --vault Private --fields notesPlain`.

Then ask whether to push. Other personal machines pick the host up only after
a push, on their next `dfu` (apply + `ssh::sync`) — say so if the user asked
for it on all machines.

## 6. Final check

`ssh -G <alias> | grep -E '^(hostname|port|user|identityfile|identitiesonly|pubkeyauthentication) '`
must show the intended values, then `ssh <alias> true`.

## Common mistakes

| Mistake | Instead |
|---|---|
| "No key was mentioned, so password auth" | Make a key (step 2) and try it |
| Writing the block before step 4 passes | A key block that does not work is worse than none |
| Telling the user to install the key "later" | Step 3 is part of this skill |
| Public IP into `private_config` because it is "just a VPS" | 1Password note |
| Editing `~/.ssh/config` or `~/.ssh/config.d/*` directly | Both are overwritten — edit the sources |
