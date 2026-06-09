#!/usr/bin/env bash
# Idempotent mac setup. Safe to re-run: it reports what was already correct
# (ok), newly created (linked), or repaired (fixed). For a read-only drift
# check without changing anything, use mac-doctor.sh instead.
#
# Usage:
#   ./mac-install.sh              full setup (packages + links + keys + gh check)
#   ./mac-install.sh --links-only just re-link dotfiles + ssh + keys (skip brew/omz/nvm/npm)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
source "$ROOT/mac/manifest.sh"
DOTFILES="$DOTFILES_MAC"

LINKS_ONLY=0
[ "${1:-}" = "--links-only" ] && LINKS_ONLY=1

tilde() { echo "${1/#$HOME/~}"; }

# Idempotent symlink: ok if already correct, fixed if wrong/real-file (backed up), linked if new.
link() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ]; then
    if [ "$(readlink "$dest")" = "$src" ]; then
      echo "  ok:     $(tilde "$dest")"; return
    fi
    local old; old="$(readlink "$dest")"
    rm "$dest"; ln -s "$src" "$dest"
    echo "  fixed:  $(tilde "$dest") (was -> $old)"
  elif [ -e "$dest" ]; then
    local bak="$dest.bak.$(date +%Y%m%d%H%M%S)"
    mv "$dest" "$bak"; ln -s "$src" "$dest"
    echo "  fixed:  $(tilde "$dest") (real file backed up to $(tilde "$bak"))"
  else
    ln -s "$src" "$dest"; echo "  linked: $(tilde "$dest")"
  fi
}

if [ "$LINKS_ONLY" -eq 0 ]; then
  echo "==> Installing Homebrew packages..."
  brew bundle --file="$DOTFILES/Brewfile"

  echo "==> Installing oh-my-zsh..."
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi

  echo "==> Installing zsh plugins..."
  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && \
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" || true
  [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" || true
  [ ! -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ] && \
    git clone https://github.com/zsh-users/zsh-history-substring-search "$ZSH_CUSTOM/plugins/zsh-history-substring-search" || true

  echo "==> Installing nvm..."
  if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  fi
  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm install --lts
  nvm alias default node

  echo "==> Installing npm globals..."
  npm install -g @openai/codex

  echo "==> Installing webfetch (headless-Chromium page -> markdown)..."
  ( cd "$ROOT/tools/webfetch" && npm ci --no-fund --no-audit && npx --yes playwright install chromium )
fi

echo "==> Linking dotfiles..."
for entry in "${DOTFILE_LINKS[@]}"; do
  link "$DOTFILES/${entry%%|*}" "${entry#*|}"
done
chmod 700 "$HOME/.ssh" 2>/dev/null || true
chmod 600 "$HOME/.ssh/config" 2>/dev/null || true

echo "==> GitHub SSH keys..."
NEW_KEYS=()
for acct in "${GH_ACCOUNTS[@]}"; do
  IFS='|' read -r folder user keyfile alias email <<<"$acct"
  if [ ! -f "$HOME/.ssh/$keyfile" ]; then
    ssh-keygen -t ed25519 -C "$user@github" -f "$HOME/.ssh/$keyfile" -N "" -q
    echo "  generated: $keyfile ($user)"
    NEW_KEYS+=("$keyfile|$user")
  else
    echo "  ok:        $keyfile ($user)"
  fi
done
if [ ${#NEW_KEYS[@]} -gt 0 ]; then
  echo ""
  echo "  New keys generated -- add each public key to the matching GitHub account:"
  for entry in "${NEW_KEYS[@]}"; do
    keyfile="${entry%%|*}"; user="${entry#*|}"
    echo ""
    echo "  --- $keyfile (account: $user) ---"
    cat "$HOME/.ssh/$keyfile.pub"
  done
  echo ""
  echo "  Add at: https://github.com/settings/keys (logged in as each account)"
fi

echo "==> gh CLI auth..."
if command -v gh >/dev/null 2>&1; then
  status="$(gh auth status 2>&1 || true)"
  for acct in "${GH_ACCOUNTS[@]}"; do
    IFS='|' read -r folder user keyfile alias email <<<"$acct"
    if echo "$status" | grep -q "account $user"; then
      echo "  ok:     gh authed as $user"
    else
      echo "  todo:   gh NOT authed as $user -- run: gh auth login --hostname github.com --git-protocol ssh   (sign in as $user)"
    fi
  done
else
  echo "  gh not installed (brew bundle installs it; re-run without --links-only)"
fi

if [ "$LINKS_ONLY" -eq 0 ]; then
  echo "==> VSCode extensions..."
  if command -v code >/dev/null 2>&1; then
    while IFS= read -r ext; do
      [ -z "$ext" ] && continue
      code --install-extension "$ext" --force >/dev/null 2>&1 || echo "  skipped: $ext"
    done < "$DOTFILES/vscode/extensions.txt"
  else
    echo "  'code' CLI not in PATH -- open VSCode, run Shell Command: Install 'code' command, then re-run"
  fi
fi

echo ""
echo "Done. Verify with: $ROOT/mac-doctor.sh    then: exec zsh"
