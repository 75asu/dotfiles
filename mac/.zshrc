export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search)
source $ZSH/oh-my-zsh.sh

# History
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# Path
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"

# Aliases
source "$HOME/.aliases.zsh"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# goenv
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)" 2>/dev/null || :

# fzf (Ctrl+R history search, Ctrl+T file search)
eval "$(fzf --zsh)"

# Autosuggestions — accept with right arrow, partial accept with Ctrl+F
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
bindkey '^F' forward-word

# History substring search — up/down arrows search through history
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# OrbStack
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# Starship (must be last)
eval "$(starship init zsh)"
