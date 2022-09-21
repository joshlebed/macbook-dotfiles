# for new setup, hardlink this file 

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

# other aliases
alias karabiner-build="cd ~/.config/karabiner && node file-watcher.js"
alias p="python3"

# load environment specifics if there are any (home config, work config)
test -e "${HOME}/.environment-specifics.zshrc" && source "${HOME}/.environment-specifics.zshrc" || true
