#!/usr/bin/env bash
set -e

DOTFILES="$(cd "$(dirname "$0")/linux" && pwd)"

echo "==> Installing apt packages..."
sudo apt-get update -qq
sudo apt-get install -y \
  git curl wget unzip zip \
  zsh tmux fzf \
  jq tree htop watch \
  xclip build-essential

echo "==> Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/kubectl

echo "==> Installing helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "==> Installing terraform..."
wget -O /tmp/terraform.zip "https://releases.hashicorp.com/terraform/$(curl -sL https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r .current_version)/terraform_$(curl -sL https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r .current_version)_linux_amd64.zip"
unzip /tmp/terraform.zip -d /tmp && sudo mv /tmp/terraform /usr/local/bin/terraform

echo "==> Installing Go..."
GO_VERSION=$(curl -sL "https://go.dev/dl/?mode=json" | jq -r '.[0].version')
curl -Lo /tmp/go.tar.gz "https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf /tmp/go.tar.gz

echo "==> Installing starship..."
curl -sS https://starship.rs/install.sh | sh -s -- -y

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

echo "==> Installing nvm + Node LTS (for webfetch)..."
if [ ! -d "$HOME/.nvm" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi
export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts && nvm alias default node

echo "==> Installing webfetch (headless-Chromium page -> markdown)..."
( cd "$DOTFILES/../tools/webfetch" && npm ci && npx --yes playwright install --with-deps chromium )
mkdir -p "$HOME/.local/bin"
ln -sf "$DOTFILES/../tools/webfetch/webfetch" "$HOME/.local/bin/webfetch"

echo "==> Linking dotfiles..."
ln -sf "$DOTFILES/.zshrc"               "$HOME/.zshrc"
ln -sf "$DOTFILES/.gitconfig"           "$HOME/.gitconfig"
ln -sf "$DOTFILES/.tmux.conf"           "$HOME/.tmux.conf"
ln -sf "$DOTFILES/aliases.zsh"          "$HOME/.aliases.zsh"
mkdir -p "$HOME/.config"
ln -sf "$DOTFILES/config/starship.toml" "$HOME/.config/starship.toml"

echo "==> Setting zsh as default shell..."
chsh -s "$(which zsh)"

echo ""
echo "Done. Log out and back in, then run: exec zsh"
