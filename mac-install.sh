#!/usr/bin/env bash
set -e

DOTFILES="$(cd "$(dirname "$0")/mac" && pwd)"

echo "==> Installing Homebrew packages..."
brew bundle --file="$DOTFILES/Brewfile"

echo "==> Installing oh-my-zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

echo "==> Installing zsh plugins..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && \
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && \
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

echo "==> Linking dotfiles..."
ln -sf "$DOTFILES/.zshrc"              "$HOME/.zshrc"
ln -sf "$DOTFILES/.zprofile"           "$HOME/.zprofile"
ln -sf "$DOTFILES/.gitconfig"          "$HOME/.gitconfig"
ln -sf "$DOTFILES/.tmux.conf"          "$HOME/.tmux.conf"
ln -sf "$DOTFILES/aliases.zsh"         "$HOME/.aliases.zsh"
mkdir -p "$HOME/.config"
ln -sf "$DOTFILES/config/starship.toml" "$HOME/.config/starship.toml"

echo ""
echo "Done. Run: exec zsh"
