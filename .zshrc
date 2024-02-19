# for new setup, hardlink this file (see readme)

# oh-my-zsh config
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster-custom"
plugins=(git)
source $ZSH/oh-my-zsh.sh
export EDITOR='vi -e'
export VISUAL='code'

# iterm config
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh" || true

# git aliases
alias gs="git status"
alias la="ls -a"
alias gc="git commit -m"
alias gpp="git push --set-upstream origin"
alias config="code ~/.config"
alias history="code ~/.zsh_history"
alias restart-ha='curl -X POST -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJhOWE5YmVkMDQ5YTY0MjUxOGY0OTc1ZTYzMTIxNjA3NCIsImlhdCI6MTY2NjA3MDIyMSwiZXhwIjoxOTgxNDMwMjIxfQ.Dz_oPS2tIup2PB89bi6SFAZHxortQh3kZ5hrw-gWdu4" -H "Content-Type: application/json" 192.168.0.181:8123/api/services/homeassistant/restart'
alias reload-zsh-config="source ~/.zshrc"
alias z="source ~/.zshrc"
alias temp='sudo powermetrics --samplers smc |grep -i "CPU die temperature"'

# other aliases
alias karabiner-build="cd ~/.config/karabiner && node file-watcher.js"
alias p="python3"
alias kill-bluetooth="sudo pkill bluetoothd"

# load environment specifics if there are any (home config, work config)
test -e "${HOME}/.environment-specifics.zshrc" && source "${HOME}/.environment-specifics.zshrc" || true
