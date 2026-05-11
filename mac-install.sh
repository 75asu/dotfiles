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

echo "==> Installing nvm..."
if [ ! -d "$HOME/.nvm" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm alias default node

echo "==> Installing npm globals..."
npm install -g @openai/codex

echo "==> Linking dotfiles..."
ln -sf "$DOTFILES/.zshrc"              "$HOME/.zshrc"
ln -sf "$DOTFILES/.zprofile"           "$HOME/.zprofile"
ln -sf "$DOTFILES/.gitconfig"          "$HOME/.gitconfig"
ln -sf "$DOTFILES/.tmux.conf"          "$HOME/.tmux.conf"
ln -sf "$DOTFILES/aliases.zsh"         "$HOME/.aliases.zsh"
mkdir -p "$HOME/.config"
ln -sf "$DOTFILES/config/starship.toml" "$HOME/.config/starship.toml"

echo "==> Setting up VSCode..."
VSCODE_USER="$HOME/Library/Application Support/Code/User"
mkdir -p "$VSCODE_USER"
ln -sf "$DOTFILES/vscode/settings.json" "$VSCODE_USER/settings.json"
if command -v code &>/dev/null; then
  while IFS= read -r ext; do
    [[ -z "$ext" ]] && continue
    code --install-extension "$ext" --force 2>/dev/null || echo "  skipped: $ext"
  done < "$DOTFILES/vscode/extensions.txt"
else
  echo "  'code' CLI not in PATH - open VSCode, run: Shell Command: Install 'code' command in PATH, then re-run this script"
fi

echo ""
echo "Done. Run: exec zsh"
