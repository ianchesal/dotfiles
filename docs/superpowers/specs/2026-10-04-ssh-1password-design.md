# Design: SSH keys and config from 1Password

Date: 2026-10-04
Status: implemented on branch ssh-1password
Repos in scope: `ianchesal/dotfiles`

## Problem

`~/.ssh` is hand-maintained and per-machine. Private keys sit on disk in the
clear (eight of nine have no passphrase), `~/.ssh/config` is not in the source
state and carries stale entries (hard-coded `/Users/ian/...` Heroku paths), and
a new machine — the Mac mini first — has to be set up by copying files around.

Goal: private keys live **only** in 1Password, and every personal machine gets
the same `~/.ssh/config` from the repo plus 1Password, with nothing to copy by
hand. Work machines and the cloud workstation are left alone.

## Verified constraints

Checked on the WSL2 box on 2026-10-04, not assumed.

- **Most keys are already in 1Password.** The Private vault holds SSH Key items
  whose fingerprints match the on-disk `synology01`, `digitalocean` ("Digital
  Ocean"), `tranquility` ("ian@tranquility"), `rpi-basement-1`, `fractal-audio`
  ("Fractal") and `aws-personal`, plus `Github Personal`, `Persona SSH Key` and
  `Bitbucket Personal`, which have no on-disk copy here. For every
  unencrypted on-disk key the fingerprint was derived from the private half;
  `digitalocean` has a passphrase and was matched on its `.pub` only.
- **`op whoami` cannot detect sign-in.** Signed out, it still prints the account identity and exits 0, while `op item list` and `op vault get` exit 1 with `You are not currently signed in` (op 2.40.0, verified 2026-10-04). The auth probe is `op vault get "$OP_VAULT"`.
- **Keys only on disk:** `id_rsa` (comment changed from
  `ichesal@DESKTOP-MP4PLF9` to `ian@dads-gaming-pc` on 2026-10-04; used by
  `fractal-devenv`) — imported. `home-router` and both `identity.heroku.*` —
  dead, retired, not imported.
- **`op` cannot import an existing private key.** `op item create` only offers
  `--ssh-generate-key`; importing is a 1Password app step.
- **`op read` rejects `@` in a secret reference** (`invalid character in secret
  reference: '@'`), and two item titles contain one. `op item get '<title>'
  --fields 'public key'` works, and returns the key without its comment.
- **`IdentityAgent` overrides `SSH_AUTH_SOCK`, silently.** Pointed at a
  nonexistent socket, ssh logs only at `debug1`
  (`get_agent_identities: ssh_get_authentication_socket: No such file or
  directory`) and continues with **no agent at all** — a forwarded or
  hand-started agent is ignored. An unconditional `IdentityAgent` is therefore
  unsafe; it must be guarded on the socket existing. `Match exec "test -S
  <sock>"` does that: tested with `ssh -G`, the socket absent leaves
  `identityagent` unset (so `SSH_AUTH_SOCK` applies), present sets it, and `~`
  expands inside the `exec` command.
- **ssh takes the first value obtained for each option.** `Include` placed at
  the top of `~/.ssh/config` therefore lets `config.d/` entries win over the
  skeleton, and an `Include` glob that matches nothing is not an error.
- **The agent offers every key it holds unless the host restricts it.** With
  nine keys, a host can hit the server's `MaxAuthTries` (6 by default) before
  the right key — or password auth — is reached. Pinning is `IdentityFile
  <key>.pub` + `IdentitiesOnly yes`; password-only hosts need `PubkeyAuthentication no`.
  `imac` and `udm-pro` are password-only today.
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
  app, which shows Touch ID on the Mac's own screen. **Over SSH it blocks**
  (confirmed by the user, 2026-10-04): the auth prompt appears on the Mac's
  display, invisible and unanswerable from the SSH session, and `op` waits on
  it.
- **chezmoi's `private_` is per entry.** A scratch apply of
  `private_dot_ssh/config` gave the directory 0700 but the file **0644**;
  `private_dot_ssh/private_config` gave 0600.
- **Nothing creates `~/.work_machine`**, including
  `bootstrap/cloud-workstation.sh`. gcw is detected by `/etc/workstation-startup.d`
  (`zshrc.d/machine.zsh`).
- **Brewfile additions do not reach existing machines.** `brew bundle` runs only
  from the `run_once_before` bootstrap; `brew::update` upgrades only what is
  installed. `socat` is not installed on the WSL box; `npiperelay.exe` is not on
  its PATH.
- **The `1password-cli` cask works on Linux.** `op` on the WSL box resolves to
  `/home/linuxbrew/.linuxbrew/Caskroom/1password-cli/2.40.0/op`, installed by
  hand outside the Brewfile.
- **`just lint` names every script explicitly**; a new script is not
  shellchecked unless added to the list.
- **The repo is public.** Host blocks with public IPs (Fractal servers,
  chesal.net) do not go in it. LAN (`192.168.1.x`) hosts and public keys may.

## Design

### 1. What chezmoi deploys

`home/private_dot_ssh/private_config` → `~/.ssh/config` (0600). Plain file, no
template — the socket path is the same on every platform (see the symlink
below). In order:

1. `Include config.d/*` — first, so 1Password-sourced entries win.
2. LAN hosts (the non-sensitive skeleton):
   - `rpi-basement-1`, `tranquility`, `synology01`, `fractal-devenv` (→
     `dads-gaming-pc.pub`): each pins its `.pub` with `IdentitiesOnly yes`.
   - `imac`, `udm-pro`: `# password auth` comment and
     `PubkeyAuthentication no`, so the agent never offers keys to them.
3. `Host github.com`, pinned to `github-personal.pub`, `IdentitiesOnly yes`.
4. Last, a guarded agent block:
   ```
   Match exec "test -S ~/.1password/agent.sock" !exec "test -n \"$SSH_CONNECTION\" -a -S \"$SSH_AUTH_SOCK\""
     IdentityAgent ~/.1password/agent.sock
   ```
   When the socket is absent nothing is set, so ssh falls back to
   `SSH_AUTH_SOCK` (a forwarded or hand-started agent) instead of to no agent.
   Forwarded-agent exception: inside an SSH session (`SSH_CONNECTION` set) whose
   `SSH_AUTH_SOCK` names an existing socket, the block does not match, so the
   forwarded agent wins. Otherwise ssh/git over SSH would go to 1Password, and
   on macOS its approval prompt would land on the console and hang.

`home/private_dot_1password/symlink_agent.sock.tmpl` → `~/.1password/agent.sock`
on **macOS only**, pointing at
`{{ .chezmoi.homeDir }}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`.
This is the layout 1Password's own docs recommend, and it gives every platform
one socket path: native Linux 1Password creates `~/.1password/agent.sock`
itself, and the WSL relay (§3) serves it there. `.chezmoiignore` skips
`.1password` on non-darwin so chezmoi never touches the relay's socket.

Public keys deploy as `home/private_dot_ssh/<name>.pub`, mode 0644 (public
keys need no protection; ssh accepts it). Read once from 1Password with
`op item get '<item title>' --vault Private --fields 'public key'` and
committed: `rpi-basement-1`, `tranquility`, `synology01`, `fractal-audio`,
`digitalocean`, `github-personal`, and `dads-gaming-pc` (item
`ian@dads-gaming-pc`). `fractal-audio` and `digitalocean` are referenced from
`config.d/` notes, not the skeleton. Excluded: `persona` (work),
`bitbucket-personal` (unused), `aws-personal` (no host uses it; the agent still
offers it).

`home/.chezmoiignore` (new, templated):

- ignores `.ssh` and `.ssh/**` when `~/.work_machine` exists **or**
  `/etc/workstation-startup.d` exists (gcw, same detector as `machine.zsh`);
- ignores `.1password` and `.1password/**` unless `.chezmoi.os` is `darwin`,
  and also on work and gcw boxes (same conditions as `.ssh`).

Both use `stat`, so the files are the source of truth, never an exported
variable. Skipping `.ssh` on work and gcw boxes is a **deliberate exception** to
the repo rule that every config deploys everywhere, and AGENTS.md says so.

No `exact_` prefix on `.ssh`: `known_hosts`, `authorized_keys` and `config.d/`
stay machine-local and untouched by chezmoi.

### 2. `script/ssh-config-sync` and `just ssh::sync`

Host blocks too sensitive for the repo live in 1Password as **Secure Notes in
the Private vault tagged `ssh-config`**. The item title is the file name; the
note body is the raw `Host ...` block(s).

The script, in order:

1. **No-ops** (exit 0, one-line notice) when `op` is not on PATH, when
   `~/.work_machine` exists, or when `/etc/workstation-startup.d` exists.
   Also skips (exit 0, **without calling `op` at all**) on macOS when
   `SSH_CONNECTION` is set, printing
   `1Password would prompt on the Mac's display -- skipping over SSH. Run 'just ssh::sync' at the console.`
   Calling `op` there would block on a prompt nobody can answer.
2. **Preflights auth with `op vault get "$OP_VAULT"`, bounded by a timeout** (`OP_TIMEOUT`,
   default 60s; a bash background watchdog, since macOS has no `timeout(1)`).
   The timeout is a backstop for an unattended console session (screen locked,
   nobody there), not the SSH case, which step 1 already handles.
   On failure or timeout it prints
   `1Password CLI not signed in -- skipping. Run: eval "$(op signin)" && just ssh::sync`,
   touches nothing, and exits 0, so a locked, signed-out or unattended
   1Password never fails or hangs the `update` fan-out. The script never signs
   in itself. On macOS with app integration this is where Touch ID appears.
3. **Fetches everything before writing anything.**
   - `op item list --vault "$OP_VAULT" --tags "$OP_TAG" --format json`.
   - For each item, `op item get <id> --format json`, extracting the body with
     `jq -r '.fields[] | select(.id == "notesPlain") | .value // ""'`.
   - Any `op` or `jq` failure after the preflight passed (network, malformed
     JSON, a vanished vault) is a real fault: write nothing, delete nothing,
     exit non-zero.
4. **Validates the set**, still before writing:
   - A title must match `^[A-Za-z0-9][A-Za-z0-9._-]*$` (leading alphanumeric:
     rules out `.`, `..` and hidden files). A bad title is skipped with a
     warning.
   - Two items whose titles match ignoring case are a fault: exit non-zero, write
     nothing (on macOS they would be the same file).
   - An empty body is skipped with a warning; no header-only file.
5. **Writes** each file to `config.d/<title>` atomically (temp file in the same
   directory, then `mv`), mode 0600, directory 0700, with a first line of
   `# managed by ssh-config-sync -- edit in 1Password: <title>`.
6. **Prunes** files in `config.d/` that carry that header but no longer have an
   item. Files without the header are never touched. **Guard:** if the fetch
   returned zero items while managed files exist, warn and prune nothing — a
   tag typo or a lost tag must not wipe the directory. Removing the last note
   on purpose means deleting its file by hand.

Env seams: `OP_BIN`, `OP_ACCOUNT` (passed as `--account` when set; unset
means the single signed-in account), `OP_VAULT` (default `Private`), `OP_TAG`
(default `ssh-config`), `OP_TIMEOUT`, `SSH_CONFIG_D`, `WORK_MACHINE_FLAG`,
`GCW_MARKER`, `UNAME_S` (default `$(uname -s)`, so tests can exercise the
`Darwin` + `SSH_CONNECTION` skip on Linux).

Wiring: `just/ssh.just` with a documented `sync` recipe; `mod ssh` in the root
justfile; `ssh::sync` appended to the `update` fan-out so `dfu` keeps every
personal machine current; `script/ssh-config-sync` added to `just lint`'s
shellcheck list.

### 3. Agent wiring

`home/dot_config/zsh/zshrc.d/1password.zsh` (does nothing on work or gcw boxes:
the whole body is skipped when `~/.work_machine` or `/etc/workstation-startup.d`
exists, tested as file/dir, never via an exported variable):

- **WSL relay** — WSL only (kernel release contains `microsoft`), when
  `npiperelay.exe`, `socat` and `flock` are on PATH:
  - Under `flock ~/.1password/.relay.lock`, re-check liveness (`ssh-add -l`
    against the socket exits 2 = dead). If dead, remove any stale socket file
    and start
    `setsid socat UNIX-LISTEN:$HOME/.1password/agent.sock,fork
    EXEC:"npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork`
    detached, so it outlives the launching shell. Serialising prevents several
    shells started at once (tmux restoring panes) from each unlinking the
    others' socket and orphaning socat processes.
  - Creates `~/.1password` (0700) if needed.
- **`SSH_AUTH_SOCK`, all platforms** — export it to `~/.1password/agent.sock`
  when that socket exists (`-S`), **unless** `SSH_CONNECTION` is set and the
  existing `SSH_AUTH_SOCK` exists (`-S`; keep a forwarded agent). The WSL relay
  branch above does a real liveness check (`ssh-add -l`, bounded by
  `timeout 2` where available) before this.
- No bash port: the bash config targets machines without 1Password.

Brewfile additions: `jq`, `socat` and `cask "1password-cli"`, all
unconditional (the cask works on Linux and WSL is where the sync runs most).
The 1Password **app** stays out of the Brewfile: `brew bundle` fails with
"It seems there is already an App at …" when the app was installed outside
Homebrew, and the app updates itself.

`just doctor`: on WSL, warn when `npiperelay.exe` is not on PATH (fix:
`winget install albertony.npiperelay`); everywhere, warn when
`~/.ssh/config` exists on a work or gcw box and looks chezmoi-managed.

Manual, per machine (1Password settings cannot be automated): enable
*Settings → Developer → Use the SSH agent*. On Windows additionally stop and
disable the built-in *OpenSSH Authentication Agent* service, which competes for
the same pipe.

### 4. One-time migration runbook

Run by hand. Every destructive step comes after verification.

0. **Before merging:** confirm `~/.work_machine` exists on every work machine,
   so the first `dfu` after this ships cannot replace a work `~/.ssh/config`.
   Likewise, **before merging / before each personal machine's next `dfu`:**
   enable the 1Password SSH agent (and, on WSL, have the relay running) and
   confirm `ssh-add -l` lists the keys. The deployed config pins
   `IdentityFile ~/.ssh/<name>.pub` + `IdentitiesOnly yes`; ssh does not fall
   back to the on-disk private key, so pinned hosts and github.com stop working
   on a machine whose agent is not set up.
1. ~~Import `~/.ssh/id_rsa` into 1Password.~~ Done 2026-10-04: item
   `ian@dads-gaming-pc`, fingerprint
   `SHA256:XSc3vPUj+r5GUwTfcnwYdlHKiYlCgUSyn+U/j7tCoNo` verified.
2. Create Secure Notes tagged `ssh-config` in Private:
   - `fractal` — the `fractal-host2 fractal-web fractal-wiki factal-axechange`
     and `fractal-xenforo` blocks, `IdentityFile ~/.ssh/fractal-audio.pub`.
   - `chesal.net` — its block, `IdentityFile ~/.ssh/digitalocean.pub`.
3. **Install prerequisites on this machine** (Brewfile changes do not reach it):
   `brew bundle install --file="$(git rev-parse --show-toplevel)/brew/Brewfile"`.
   On WSL also: `winget install albertony.npiperelay`; enable the 1Password SSH
   agent; disable the Windows *OpenSSH Authentication Agent* service. Open a
   new shell and confirm `ssh-add -l` lists the 1Password keys **before**
   touching the config.
4. `cp ~/.ssh/config ~/.ssh/config.pre-chezmoi` (chezmoi keeps no backup), then
   `chezmoi diff ~/.ssh`, `chezmoi apply ~/.ssh`, `just ssh::sync`.
5. Verify: `ssh -G <host>` for every host resolves the right
   `identityfile`/`identityagent` (and `pubkeyauthentication false` for `imac`,
   `udm-pro`); a real login to each reachable host, including `chesal.net`
   (proves the passphrase-protected `digitalocean` key in 1Password);
   `ssh -T git@github.com`.
6. Only then delete from `~/.ssh`: every private key (`aws-personal`,
   `digitalocean`, `fractal-audio`, `home-router`, `identity.heroku.*`,
   `id_rsa`, `synology01`, `tranquility`), **`id_rsa.bak` and
   `id_rsa.pub.bak`**, the `home-router.pub`, `identity.heroku.*.pub` and
   `id_rsa.pub` public keys, `environment`, and `config.pre-chezmoi` once
   satisfied. Finish with `grep -l 'PRIVATE KEY' ~/.ssh/*`, which must print
   nothing.
7. Mac mini: bootstrap, enable the 1Password SSH agent and CLI integration,
   `chezmoi apply`, `just ssh::sync`, then step 5. Also: confirm
   `~/.1password/agent.sock` is the symlink and `ssh -G github.com | grep
   identityagent` shows it; run `just ssh::sync` from an SSH session to the
   Mac and confirm it skips immediately with the over-SSH notice.

### 5. Testing and docs

- `script/tests/ssh-config-sync.test.sh` against a fake `op`:
  - writes items with header and modes;
  - prunes only managed files; leaves an unmanaged file alone;
  - zero items with managed files present → warns, prunes nothing;
  - rejects bad titles, including `.`, `..` and `.hidden`;
  - duplicate titles → non-zero, nothing written;
  - empty note body → skipped with a warning;
  - no-ops without `op`, on a work machine, and on a gcw marker;
  - the vault check failing → exit 0, nothing touched;
  - the vault check hanging past `OP_TIMEOUT` → exit 0, nothing touched;
  - `UNAME_S=Darwin` with `SSH_CONNECTION` set → exit 0, `op` never invoked;
  - an `op` failure after the preflight → non-zero, nothing changed;
  - `OP_ACCOUNT` set → `--account` passed to every `op` call.
- `just lint` (with the new script in its list) and `just test-scripts` pass.
- `chezmoi --source "$(git rev-parse --show-toplevel)" diff ~/.ssh` inspected
  before any apply; file modes checked after (`config` 0600, `.ssh` 0700).
- Docs: an "SSH Configuration" section in `AGENTS.md`, plus AGENTS.md's
  "Three chezmoi control files" bullet (now four, with `.chezmoiignore`), the
  "every config deploys on every platform" bullet (the `.ssh` and `.1password`
  exceptions), and the prefix counts (`private_`, `symlink_` gains a second
  entry); `docs/tools/ssh.md`; a note in `docs/chezmoi-workflows.md`.

## Trade-offs accepted

- **LAN IPs and usernames are published.** Low value to an attacker; keeping
  them in the skeleton means most hosts work even before `ssh::sync` runs.
- **`config.d/` lags 1Password until the next `dfu`/`just ssh::sync`.** Chosen
  over a chezmoi `run_` script so `chezmoi apply` never prompts for 1Password
  and never fails because it is locked.
- **`Match exec` forks a shell per connection.** A few milliseconds, in
  exchange for never disabling a forwarded agent.
- **WSL depends on a Windows-side binary** (`npiperelay.exe`) that chezmoi
  cannot install. `just doctor` flags its absence.
- **The 1Password app is installed by hand** on each Mac, not by the Brewfile.

## Out of scope

- Git commit signing through 1Password.
- `known_hosts` (machine-local).
- Work machines, the cloud workstation (both excluded by `.chezmoiignore`), and
  parachute boxes.
- Replacing the RSA keys with ed25519.
- Moving `imac` and `udm-pro` to key auth.
