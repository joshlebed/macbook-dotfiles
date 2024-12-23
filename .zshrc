# for new setup, hardlink this file (see readme)

# oh-my-zsh config
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster-custom"
plugins=(git)
source $ZSH/oh-my-zsh.sh
export EDITOR=vim
export VISUAL=code

# NVM (node version manager) setup
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"                                       # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion

# PYENV (python version manager) setup
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
export PATH=/usr/local/bin:$PATH
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# Enable fzf key bindings and completion
# intel mac
[ -f /usr/local/opt/fzf/shell/completion.zsh ] && source /usr/local/opt/fzf/shell/completion.zsh
[ -f /usr/local/opt/fzf/shell/key-bindings.zsh ] && source /usr/local/opt/fzf/shell/key-bindings.zsh
# arm mac
[ -f /opt/homebrew/opt/fzf/shell/completion.zsh ] && source /opt/homebrew/opt/fzf/shell/completion.zsh
[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ] && source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
# raspberry pi/debian
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh

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

# python virtualenvwrapper config
export VIRTUALENVWRAPPER_PYTHON=/usr/local/bin/python3.10
export WORKON_HOME=$HOME/.virtualenvs
export PROJECT_HOME=$HOME/code
[ -f /opt/homebrew/bin/virtualenvwrapper.sh ] && source /opt/homebrew/bin/virtualenvwrapper.sh

# pnpm
export PNPM_HOME="/Users/joshlebed/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# libsync
LIBSYNC_REPO_DIRECTORY='/Users/joshlebed/code/lib-sync' # update to the path to the repo on your machine
alias libsync-dev="${LIBSYNC_REPO_DIRECTORY}/.venv/bin/python ${LIBSYNC_REPO_DIRECTORY}/libsync/libsync.py"
alias libsync-run-sync="cd ${LIBSYNC_REPO_DIRECTORY} && ${LIBSYNC_REPO_DIRECTORY}/scripts/run_sync.sh"
alias libsync-run-sync-edit="cd ${LIBSYNC_REPO_DIRECTORY} && code ${LIBSYNC_REPO_DIRECTORY}/scripts/run_sync.sh"
alias webp-convert-downloads="magick mogrify -format JPEG ~/downloads/*.webp && open ~/downloads"
alias wav-convert-mp3='for i in *.wav; do ffmpeg -i "$i" -ab 320k "${i%.*}.mp3"; done # convert all wavs in this directory to mp3s at 320kbps'
alias flac-convert-mp3='for i in *.flac; do ffmpeg -i "$i" -ab 320k "${i%.*}.mp3"; done # convert all flacs in this directory to mp3s at 320kbps'
alias m4a-convert-mp3='for i in *.m4a; do ffmpeg -i "$i" -ab 320k "${i%.*}.mp3"; done # convert all m4as in this directory to mp3s at 320kbps'
alias opus-convert-mp3='for i in *.opus; do ffmpeg -i "$i" -ab 320k "${i%.*}.mp3"; done # convert all opuss in this directory to mp3s at 320kbps'

# load environment specifics if there are any (home config, work config)
test -e "${HOME}/.environment-specifics.zshrc" && source "${HOME}/.environment-specifics.zshrc" || true
