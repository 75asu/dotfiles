# Single source of truth for the mac dotfiles setup.
# Data only -- no side effects. Sourced by:
#   - mac-install.sh  (apply, idempotent)
#   - mac-doctor.sh   (verify drift, read-only)
# Keeping the symlink map and account table here means apply and verify can
# never disagree about what "correct" looks like.

# Absolute path to this mac/ profile dir, regardless of who sources us.
DOTFILES_MAC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Where per-account repos live. The includeIf rules in .gitconfig and the
# folder prefixes in the gh() wrapper (aliases.zsh) must match this layout.
GH_CLONES_ROOT="$HOME/gh-clones"

# Managed symlinks: "<src relative to DOTFILES_MAC>|<absolute dest>"
# dest may contain $HOME and spaces.
DOTFILE_LINKS=(
  ".zshrc|$HOME/.zshrc"
  ".zprofile|$HOME/.zprofile"
  ".gitconfig|$HOME/.gitconfig"
  ".gitconfig-personal|$HOME/.gitconfig-personal"
  ".gitconfig-one2n|$HOME/.gitconfig-one2n"
  ".gitconfig-fravity|$HOME/.gitconfig-fravity"
  ".tmux.conf|$HOME/.tmux.conf"
  "aliases.zsh|$HOME/.aliases.zsh"
  "config/starship.toml|$HOME/.config/starship.toml"
  "ssh_config|$HOME/.ssh/config"
  "vscode/settings.json|$HOME/Library/Application Support/Code/User/settings.json"
)

# GitHub accounts: "<folder>|<github user>|<ssh key file>|<ssh host alias>|<email>"
# <folder> is relative to GH_CLONES_ROOT. This is the canonical mapping that the
# includeIf rules (.gitconfig), the Host aliases (ssh_config), the per-account
# sshCommand (.gitconfig-<acct>), and the gh() wrapper (aliases.zsh) all encode.
GH_ACCOUNTS=(
  "gh-clones-personal|75asu|id_ed25519_75asu|github-75asu|asutosh.pda@gmail.com"
  "gh-clones-fravityai|fravity-asu|id_ed25519_fravityasu|github-fravityasu|apanda@fravity.ai"
  "gh-clones-one2n|asuu26|id_ed25519_asuu26|github-asuu26|asutosh.panda@one2n.in"
)
