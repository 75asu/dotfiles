# New Mac Remote Setup — Prerequisites

This doc covers what must be done manually on a new Mac before `mac-install.sh` can be run
remotely from another machine via SSH. Everything after this is automated.

---

## Step 1 — Enable Remote Login (SSH) on the new Mac

On the new Mac:
> System Settings → General → Sharing → Remote Login → ON

This enables the SSH daemon. Without this, no remote access is possible.

---

## Step 2 — Add this machine's public key to the new Mac

On the **control machine** (the machine you will be running from), get your public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

On the **new Mac** (via direct terminal access), add it to authorized_keys:

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo 'PASTE_PUBLIC_KEY_HERE' >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

After this, SSH from the control machine works without a password:

```bash
ssh <username>@<tailscale-ip>
```

---

## Step 3 — Grant Full Disk Access to sshd

macOS blocks SSH sessions from reading/writing `~/Documents`, `~/Desktop`, `~/Downloads` by default.
To allow SSH to access those directories:

> System Settings → Privacy & Security → Full Disk Access → click `+`
> In the file picker, press `Cmd + Shift + G` → type `/usr/sbin` → select `sshd` → Open

Then restart the SSH daemon by toggling Remote Login off and back on:
> System Settings → General → Sharing → Remote Login → OFF → ON

Without this, `cd ~/Documents/...` and `ls ~/Documents/` fail over SSH with "Operation not permitted".

---

## Step 4 — Run mac-install.sh from the control machine

Pull dotfiles on the new Mac and run the install script:

```bash
ssh <username>@<tailscale-ip> "cd ~/dotfiles && git pull && bash mac-install.sh"
```

`mac-install.sh` handles:
- Homebrew packages (Brewfile)
- oh-my-zsh + plugins
- nvm + node
- Dotfile symlinks (.zshrc, .zprofile, .gitconfig, .tmux.conf, aliases.zsh, starship)
- SSH config linking (`~/.ssh/config` → dotfiles/mac/ssh_config)
- SSH key generation (id_ed25519, id_ed25519_asuu26, id_ed25519_fravityasu) — skips if already present
- gitconfig identity files (.gitconfig-personal, .gitconfig-one2n, .gitconfig-fravity)

---

## Step 5 — Add generated public keys to GitHub

After `mac-install.sh` runs, it prints the public keys for any newly generated keys.
Add each to its corresponding GitHub account:

| Key file | GitHub account | Where to add |
|----------|---------------|--------------|
| `~/.ssh/id_ed25519.pub` | 75asu | github.com/75asu → Settings → SSH keys |
| `~/.ssh/id_ed25519_asuu26.pub` | asuu26 | github.com/asuu26 → Settings → SSH keys |
| `~/.ssh/id_ed25519_fravityasu.pub` | fravity-asu | github.com/fravity-asu → Settings → SSH keys |

Test connections after adding:

```bash
ssh <username>@<tailscale-ip> "ssh -T github-75asu 2>&1; ssh -T github-asuu26 2>&1; ssh -T github-fravityasu 2>&1"
```

Each should respond: `Hi <username>! You've successfully authenticated...`

---

## Step 6 — Install devcontainer CLI (if needed for agent-box or devcontainer projects)

`devcontainer` is not in the Brewfile (it requires node/npm). Install it via SSH after nvm is set up:

```bash
ssh <username>@<tailscale-ip> 'bash -s' << 'REMOTE'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
npm install -g @devcontainers/cli
REMOTE
```

---

## Notes on Tailscale

All remote access uses Tailscale IPs. Current nodes:

| Machine | Tailscale IP | Username |
|---------|-------------|----------|
| Personal MacBook Air (control) | 100.89.210.59 | airasu |
| One2N MacBook Air | 100.100.215.11 | mac |
| Homelab (phoenix) | 100.64.11.64 | phoenix-admin |

The homelab is already in `ssh_config` as the `homelab` host alias.
The One2N Mac is accessed directly via IP for now.

---

## Known Limitations

- `~/Documents` access via SSH requires Full Disk Access for sshd (Step 3). Even after granting,
  sometimes the permission does not propagate cleanly — if it fails, clone into `~/` directly instead.
- `osascript` (window focus, keystroke simulation) does not work over SSH — expected, not an error.
- The `code` CLI opens VSCode on the remote machine's display, not the control machine.
