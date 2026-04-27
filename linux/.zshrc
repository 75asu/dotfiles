export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# Path
export PATH="$HOME/.local/bin:/usr/local/go/bin:$HOME/go/bin:$PATH"

# Aliases
source "$HOME/.aliases.zsh"

# fzf
eval "$(fzf --zsh)"

# Starship (must be last)
eval "$(starship init zsh)"
