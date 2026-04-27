# Navigation
alias ll='ls -la'
alias ..='cd ..'
alias ...='cd ../..'

# Git
alias gs='git status'
alias gd='git diff'
alias gp='git push'
alias gpl='git pull'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gl='git log --oneline --graph --decorate'
alias gst='git stash'
alias gstp='git stash pop'

# Kubernetes
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgpa='kubectl get pods -A'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kgd='kubectl get deploy'
alias kge='kubectl get events --sort-by=.lastTimestamp'
alias kdp='kubectl describe pod'
alias kl='kubectl logs'
alias klf='kubectl logs -f'
alias kex='kubectl exec -it'
alias kns='kubectl config set-context --current --namespace'
alias kctx='kubectl config use-context'
alias kgctx='kubectl config get-contexts'

# Terraform
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfw='terraform workspace'

# Docker
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dex='docker exec -it'
alias dl='docker logs -f'
alias di='docker images'
alias dsp='docker system prune -f'

# Helm
alias h='helm'
alias hl='helm list'
alias hla='helm list -A'

# Utilities
alias watch='watch '
alias reload='exec zsh'
alias myip='curl -s ifconfig.me'
alias ports='lsof -i -P -n | grep LISTEN'
