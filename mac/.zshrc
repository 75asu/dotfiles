export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# Path
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"

# Aliases
source "$HOME/.aliases.zsh"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# fzf
eval "$(fzf --zsh)"

# OrbStack
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# Starship (must be last)
eval "$(starship init zsh)"
