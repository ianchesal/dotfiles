# Design: SSH keys and config from 1Password

Date: 2026-10-04
Status: approved for planning
Repos in scope: `ianchesal/dotfiles`

## Problem

`~/.ssh` is hand-maintained and per-machine. Private keys sit on disk in the
clear (eight of nine have no passphrase), `~/.ssh/config` is not in the source
state and carries stale entries (hard-coded `/Users/ian/...` Heroku paths), and
a new machine — the Mac mini first — has to be set up by copying files around.

Goal: private keys live **only** in 1Password, and every personal machine gets
the same `~/.ssh/config` from the repo plus 1Password, with nothing to copy by
hand. Work machines are left alone.

## Verified constraints

Checked on the WSL2 box on 2026-10-04, not assumed.

- **Most keys are already in 1Password.** The Private vault holds SSH Key items
  whose fingerprints match the on-disk `synology01`, `digitalocean` ("Digital
  Ocean"), `tranquility` ("ian@tranquility"), `rpi-basement-1`, `fractal-audio`
  ("Fractal") and `aws-personal`, plus `Github Personal`, `Persona SSH Key` and
  `Bitbucket Personal`, which have no on-disk copy here.
- **Keys only on disk:** `id_rsa` (comment changed from `ichesal@DESKTOP-MP4PLF9` to `ian@dads-gaming-pc` on 2026-10-04; used by
  `fractal-devenv`) — to be imported. `home-router` and both
  `identity.heroku.*` — dead, retired, not imported.
- **`op` cannot import an existing private key.** `op item create` only offers
  `--ssh-generate-key`; importing `id_rsa` is a 1Password app step.
- **A missing `IdentityAgent` socket is silent.** With `IdentityAgent` pointing
  at a nonexistent path, ssh logs only at `debug1`
  (`get_agent_identities: ssh_get_authentication_socket: No such file or
  directory`) and carries on. The skeleton's agent line needs no guard on a
  machine without 1Password.
- **ssh takes the first value obtained for each option.** `Include` placed at
  the top of `~/.ssh/config` therefore lets `config.d/` entries win over the
  skeleton, and an `Include` glob that matches nothing is not an error.
- **The agent offers every key it holds unless the host pins one.** With nine
  keys, an unpinned host can hit the server's `MaxAuthTries` (6 by default)
  before the right key is tried. Pinning is `IdentityFile <key>.pub` +
  `IdentitiesOnly yes` — the agent matches the public key and signs with the
  private half it holds. `rpi-basement-1` already uses this pattern.
- **WSL cannot reach the Windows agent directly.** 1Password on Windows serves
  `\\.\pipe\openssh-ssh-agent`; Linux ssh needs a unix socket. `ssh.exe` would
  reach the pipe but reads the *Windows* `%USERPROFILE%\.ssh\config`, bypassing
  everything this design deploys.
- **`op` on WSL never prompts for sign-in.** `op signin` starts an `op daemon`
  (`$XDG_RUNTIME_DIR/op-daemon.sock`) that holds the session, so child
  processes such as a `just` recipe inherit it without the `OP_SESSION_*`
  variable. Sessions end after 30 idle minutes; signed out, `op item list`
  fails immediately with `You are not currently signed in` even on a TTY.
  On macOS with the 1Password app's CLI integration, each call instead asks the
  app, which shows Touch ID (on the Mac's own screen, so not usable over SSH).
- **The repo is public.** Host blocks with public IPs (Fractal servers,
  chesal.net) do not go in it. LAN (`192.168.1.x`) hosts and public keys may.
- **`jq` is not in `brew/Brewfile`** even though the nvim updater relies on it;
  neither are `socat`, `1password` or `1password-cli`.

## Design

### 1. What chezmoi deploys

`home/private_dot_ssh/config.tmpl` → `~/.ssh/config` (0600), in this order:

1. `Include config.d/*` — first, so 1Password-sourced entries win.
2. LAN hosts (the non-sensitive skeleton): `imac`, `rpi-basement-1`,
   `tranquility`, `synology01`, `udm-pro`, `fractal-devenv`. Every one that
   authenticates by key pins its `.pub` with `IdentitiesOnly yes`.
3. `Host github.com`, pinned to `github-personal.pub`, `IdentitiesOnly yes`.
4. A final `Host *` block whose `IdentityAgent` is templated on `.chezmoi.os`:
   `"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"` on
   darwin, `~/.1password/agent.sock` everywhere else (native Linux 1Password
   and the WSL bridge in §3 share that path). This is a templated *value*, not
   OS-gated deployment.

Public keys deploy as `home/private_dot_ssh/<name>.pub`, read once from
1Password with `op item get '<item title>' --vault Private --fields 'public
key'` and committed: `rpi-basement-1`, `tranquility`, `synology01`,
`fractal-audio`, `digitalocean`, `github-personal`, and `dads-gaming-pc` (the
imported `id_rsa`, item title `ian@dads-gaming-pc`). Not `op read`: secret
references reject `@`, which appears in `ian@dads-gaming-pc` and
`ian@tranquility`. 1Password returns the public key without its comment; the
agent matches on key material, so that is harmless.
`fractal-audio` and `digitalocean` are referenced from `config.d/` notes, not
the skeleton, but their public halves are harmless to publish. Excluded:
`persona` (work), `bitbucket-personal` (unused), `aws-personal` (no host uses
it; the agent still offers it).

`home/.chezmoiignore` (new, templated) ignores `.ssh` and `.ssh/**` when
`~/.work_machine` exists, so a work machine receives nothing under `~/.ssh`.
This is a **deliberate exception** to the repo rule that every config deploys
everywhere, and AGENTS.md says so. The check uses `stat` on the flag file,
consistent with "the file is the source of truth, never the variable".

No `exact_` prefix on the directory: `known_hosts`, `authorized_keys` and
`config.d/` stay machine-local and untouched by chezmoi.

### 2. `script/ssh-config-sync` and `just ssh::sync`

Host blocks too sensitive for the repo live in 1Password as **Secure Notes in
the Private vault tagged `ssh-config`**. The item title is the file name; the
note body is the raw `Host ...` block(s).

The script:

- **No-ops** (exit 0, one-line notice) when `op` is not on PATH or
  `~/.work_machine` exists.
- **Preflights auth with `op whoami`.** On failure it prints
  `1Password CLI not signed in -- skipping. Run: eval "$(op signin)" && just ssh::sync`,
  touches nothing, and exits 0, so a locked or signed-out 1Password never fails
  the `update` fan-out. The script never tries to sign in itself: on WSL the
  session must come from the user's shell. On macOS with app integration the
  preflight is where Touch ID appears.
- Lists items with `op item list --vault Private --tags ssh-config --format
  json`, then reads each item's `notesPlain` via `op item get --format json`
  and `jq`.
- Rejects any title not matching `^[A-Za-z0-9._-]+$` (warning, skipped) — no
  path traversal through an item title.
- **Fetches everything first, then writes.** If any `op` call fails after the
  preflight passed (network, malformed JSON, a vault that vanished), it writes
  nothing, deletes nothing, and exits non-zero — that is a real fault, not a
  locked app.
- Writes each file to `~/.ssh/config.d/<title>` atomically (temp file in the
  same directory, then `mv`), mode 0600, directory 0700, with a first line of
  `# managed by ssh-config-sync -- edit in 1Password: <title>`.
- After a successful fetch, deletes files in `config.d/` that carry that header
  but no longer have an item. Files without the header are never touched.
- Env seams: `OP_BIN`, `SSH_CONFIG_D`, `WORK_MACHINE_FLAG`, `OP_VAULT`,
  `OP_TAG`.

Wiring: `just/ssh.just` with a documented `sync` recipe; `mod ssh` in the root
justfile; `ssh::sync` appended to the `update` fan-out, so `dfu` keeps every
personal machine current. `jq` is added to `brew/Brewfile`.

### 3. Agent wiring

`home/dot_config/zsh/zshrc.d/1password.zsh`:

- **WSL only** (kernel release contains `microsoft`), when `npiperelay.exe` and
  `socat` are both on PATH and the socket is not live (`ssh-add -l` against it
  exits 2): start a detached
  `socat UNIX-LISTEN:$HOME/.1password/agent.sock,fork
  EXEC:"npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork`, removing a
  stale socket file first. Creates `~/.1password` (0700) if needed.
- **All platforms:** if the platform's 1Password socket exists, export
  `SSH_AUTH_SOCK` to it, so `ssh-add -l` and other agent clients see 1Password.
- No bash port: the bash config targets machines without 1Password.

Brewfile additions: `socat` (all platforms); `cask "1password"` and
`cask "1password-cli"` on macOS only, so the Mac mini bootstrap installs them.

`just doctor`: on WSL, warn when `npiperelay.exe` is not on PATH, with the fix
`winget install albertony.npiperelay`.

Manual, per machine (1Password settings cannot be automated): enable
*Settings → Developer → Use the SSH agent*. On Windows additionally stop and
disable the built-in *OpenSSH Authentication Agent* service, which competes for
the same pipe.

### 4. One-time migration runbook

Run by hand. Every destructive step comes after verification.

1. ~~In the 1Password app, import `~/.ssh/id_rsa` into Private as an SSH Key
   item.~~ Done 2026-10-04: item `ian@dads-gaming-pc`, fingerprint
   `SHA256:XSc3vPUj+r5GUwTfcnwYdlHKiYlCgUSyn+U/j7tCoNo` verified.
2. Create Secure Notes tagged `ssh-config` in Private:
   - `fractal` — the `fractal-host2 fractal-web fractal-wiki factal-axechange`
     and `fractal-xenforo` blocks, `IdentityFile ~/.ssh/fractal-audio.pub`.
   - `chesal.net` — its block, `IdentityFile ~/.ssh/digitalocean.pub`.
3. `cp ~/.ssh/config ~/.ssh/config.pre-chezmoi` (chezmoi keeps no backup), then
   `chezmoi diff ~/.ssh`, `chezmoi apply ~/.ssh`, `just ssh::sync`.
4. Verify: `ssh -G <host>` for every host resolves the right
   `identityfile`/`identityagent`; `ssh-add -l` lists the 1Password keys; a
   real login to each reachable host; `ssh -T git@github.com`.
5. Only then delete from `~/.ssh`: all private keys, the `home-router` and
   `identity.heroku.*` public keys, the old `.pub` files now deployed by
   chezmoi under different names (`id_rsa.pub`), `environment`, and
   `config.pre-chezmoi` once satisfied.
6. Mac mini: bootstrap, enable the 1Password SSH agent, `chezmoi apply`,
   `just ssh::sync`, repeat step 4.

### 5. Testing and docs

- `script/tests/ssh-config-sync.test.sh` against a fake `op`: writes items with
  header and modes; prunes only managed files; leaves an unmanaged file alone;
  rejects a bad title; no-ops without `op`; no-ops on a work machine; skips
  with exit 0 when `op whoami` fails; an `op`
  failure mid-run changes nothing.
- `just lint` and `just test-scripts` pass.
- `chezmoi --source "$(git rev-parse --show-toplevel)" diff ~/.ssh` inspected
  before any apply. `.chezmoi.os` cannot be overridden from the CLI, so the
  darwin `IdentityAgent` branch is verified on the Mac mini in runbook step 6
  (`ssh -G github.com | grep identityagent` shows the Group Containers path).
- Docs: an "SSH Configuration" section in `AGENTS.md`, `docs/tools/ssh.md`, and
  a note in `docs/chezmoi-workflows.md`.

## Trade-offs accepted

- **LAN IPs and usernames are published.** Low value to an attacker; keeping
  them in the skeleton means most hosts work even before `ssh::sync` runs.
- **`config.d/` lags 1Password until the next `dfu`/`just ssh::sync`.** Chosen
  over a chezmoi `run_` script so `chezmoi apply` never prompts for 1Password
  and never fails because it is locked.
- **WSL depends on a Windows-side binary** (`npiperelay.exe`) that chezmoi
  cannot install. `just doctor` flags its absence.

## Out of scope

- Git commit signing through 1Password.
- `known_hosts` (machine-local).
- Work machines, the cloud workstation, and parachute boxes.
- Replacing the RSA keys with ed25519.
- Installing `op` on Linux (the sync no-ops without it).
