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
| `Brewfile` | used by `brew bundle` (Mac only) |

All files are symlinked, not copied. Edit in this repo, changes take effect immediately.

## Updating an existing machine

```bash
cd ~/dotfiles
git pull
./mac-install.sh   # or linux-install.sh - safe to re-run
```
