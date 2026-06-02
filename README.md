# dotfiles

Personal dotfiles for Mac and Linux. No magic, no conditionals - pick your machine and run one script.

## Mac

```bash
git clone https://github.com/75asu/dotfiles ~/dotfiles
cd ~/dotfiles
./mac-install.sh
exec zsh
```

Requires Homebrew to be installed first: https://brew.sh

## Linux (Ubuntu/Debian)

```bash
git clone https://github.com/75asu/dotfiles ~/dotfiles
cd ~/dotfiles
./linux-install.sh
exec zsh
```

## What's inside

| File | Where it lands |
|------|---------------|
| `.zshrc` | `~/.zshrc` |
| `.zprofile` | `~/.zprofile` (Mac only) |
| `.gitconfig` | `~/.gitconfig` |
| `.tmux.conf` | `~/.tmux.conf` |
| `aliases.zsh` | `~/.aliases.zsh` |
| `config/starship.toml` | `~/.config/starship.toml` |
| `ssh_config` | `~/.ssh/config` (Mac) |
| `vscode/settings.json` | VSCode user settings (Mac) |
| `Brewfile` | used by `brew bundle` (Mac only) |

All files are symlinked, not copied. Edit in this repo, changes take effect immediately.

The Mac symlink map and the GitHub-account table (folder -> user -> SSH key -> alias) live in `mac/manifest.sh`, which both `mac-install.sh` and `mac-doctor.sh` read, so apply and verify can never disagree.

## Verify + repair drift (Mac)

```bash
./mac-doctor.sh        # read-only: reports any drift, exits 1 if found
./mac-doctor.sh --fix  # repairs symlinks + git remotes (keys/gh-auth stay manual)
```

`mac-doctor.sh` checks: every managed symlink, the three GitHub SSH keys, the `ssh_config` host aliases, that `includeIf` resolves the right identity per `~/gh-clones/<account>/` folder, `gh` auth for all three accounts, and that every repo under `~/gh-clones/` uses its correct `git@github-<alias>` remote.

## Updating an existing machine

```bash
cd ~/dotfiles
git pull
./mac-install.sh              # safe to re-run; reports ok / linked / fixed per item
./mac-install.sh --links-only # fast path: just re-link + keys + gh check, skip brew/nvm/npm
./mac-doctor.sh               # confirm no drift
```
