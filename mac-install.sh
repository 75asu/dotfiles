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
[ ! -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ] && \
  git clone https://github.com/zsh-users/zsh-history-substring-search "$ZSH_CUSTOM/plugins/zsh-history-substring-search"

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
ln -sf "$DOTFILES/.gitconfig-personal" "$HOME/.gitconfig-personal"
ln -sf "$DOTFILES/.gitconfig-one2n"    "$HOME/.gitconfig-one2n"
ln -sf "$DOTFILES/.gitconfig-fravity"  "$HOME/.gitconfig-fravity"
ln -sf "$DOTFILES/.tmux.conf"          "$HOME/.tmux.conf"
ln -sf "$DOTFILES/aliases.zsh"         "$HOME/.aliases.zsh"
mkdir -p "$HOME/.config"
ln -sf "$DOTFILES/config/starship.toml" "$HOME/.config/starship.toml"

echo "==> Setting up SSH config and keys..."
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
ln -sf "$DOTFILES/ssh_config" "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config"

declare -A GITHUB_KEYS=(
  ["id_ed25519"]="75asu@github"
  ["id_ed25519_asuu26"]="asuu26@github"
  ["id_ed25519_fravityasu"]="fravity-asu@github"
)
KEYS_TO_ADD=()
for keyfile in "${!GITHUB_KEYS[@]}"; do
  comment="${GITHUB_KEYS[$keyfile]}"
  if [ ! -f "$HOME/.ssh/$keyfile" ]; then
    ssh-keygen -t ed25519 -C "$comment" -f "$HOME/.ssh/$keyfile" -N ""
    echo "  generated: $keyfile"
    KEYS_TO_ADD+=("$keyfile")
  else
    echo "  exists:    $keyfile (skipped)"
  fi
done

if [ ${#KEYS_TO_ADD[@]} -gt 0 ]; then
  echo ""
  echo "  New keys generated — add these public keys to GitHub before testing:"
  for keyfile in "${KEYS_TO_ADD[@]}"; do
    echo ""
    echo "  --- $keyfile (${GITHUB_KEYS[$keyfile]}) ---"
    cat "$HOME/.ssh/$keyfile.pub"
  done
  echo ""
  echo "  Test with: ssh -T github-75asu && ssh -T github-asuu26 && ssh -T github-fravityasu"
else
  echo "  All keys already present."
fi

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
