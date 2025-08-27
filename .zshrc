# for new setup, hardlink this file (see readme)

# oh-my-zsh config
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"
DEFAULT_USER="joshlebed"
REPORTTIME=2
plugins=(git)
source $ZSH/oh-my-zsh.sh
export EDITOR=vim
export VISUAL=code
export NEXT_EDITOR=code

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
alias gch="git checkout"
alias gcb="git checkout -b"
alias gpp="git push --set-upstream origin"
alias config="code ~/.config"
alias history="code ~/.zsh_history"
alias restart-ha='curl -X POST -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJhOWE5YmVkMDQ5YTY0MjUxOGY0OTc1ZTYzMTIxNjA3NCIsImlhdCI6MTY2NjA3MDIyMSwiZXhwIjoxOTgxNDMwMjIxfQ.Dz_oPS2tIup2PB89bi6SFAZHxortQh3kZ5hrw-gWdu4" -H "Content-Type: application/json" 192.168.0.181:8123/api/services/homeassistant/restart'
alias reload-zsh-config="source ~/.zshrc"
alias z="source ~/.zshrc"
alias temp='sudo powermetrics --samplers smc |grep -i "CPU die temperature"'
alias nit="git add -A && git commit -m 'nit' && git push"
alias main="git checkout main && git pull"

# other aliases
alias karabiner-build="cd ~/.config/karabiner && pnpm run build"
alias karabiner-dev="code ~/.config ~/.config/karabiner/karabiner.js && karabiner-build"
alias quicklinks-build="cd ~/.config/raycast/quicklinks && pnpm run build"
alias quicklinks-dev="code ~/.config/ ~/.config/raycast/quicklinks/quicklinks-generator.js && quicklinks-build"

alias kill-bluetooth="sudo pkill bluetoothd"

# Function to copy the output of the last command to the clipboard
alias copylast='(eval $(fc -ln -1) &> /dev/null | pbcopy)'
alias copy='copylast'
p() {
  builtin pwd -P | tee >(tr -d '\n' | pbcopy)
}
c() {
  local dir
  dir=$(ls -dt ~/code/*/ 2>/dev/null \
    | xargs -n 1 basename \
    | fzf --height=40% --reverse --border) \
    && cd ~/code/"$dir"
}

# pnpm
export PNPM_HOME="/Users/joshlebed/Library/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/joshlebed/.lmstudio/bin"
# End of LM Studio CLI section


alias claude-danger="claude --dangerously-skip-permissions"

# libsync
LIBSYNC_REPO_DIRECTORY='/Users/joshlebed/code/lib-sync' # update to the path to the repo on your machine
alias libsync-dev="cd ${LIBSYNC_REPO_DIRECTORY} && rye run libsync"
alias libsync-run-sync="cd ${LIBSYNC_REPO_DIRECTORY} && ${LIBSYNC_REPO_DIRECTORY}/scripts/run_sync.sh"
alias libsync-run-sync-edit="cd ${LIBSYNC_REPO_DIRECTORY} && code ${LIBSYNC_REPO_DIRECTORY}/scripts/run_sync.sh"
alias webp-convert-downloads="magick mogrify -format JPEG ~/downloads/*.webp && open ~/downloads"
alias wav-convert-mp3='for i in *.wav; do ffmpeg -i "$i" -ab 320k -map_metadata 0 -c:v copy "${i%.*}.mp3"; done # convert all wavs in this directory to mp3s at 320kbps'
alias flac-convert-mp3='for i in *.flac; do ffmpeg -i "$i" -ab 320k -map_metadata 0 -c:v copy "${i%.*}.mp3"; done # convert all flacs in this directory to mp3s at 320kbps'
alias m4a-convert-mp3='for i in *.m4a; do ffmpeg -i "$i" -ab 320k -map_metadata 0 -c:v copy "${i%.*}.mp3"; done # convert all m4as in this directory to mp3s at 320kbps'
alias opus-convert-mp3='for i in *.opus; do ffmpeg -i "$i" -ab 320k -map_metadata 0 -c:v copy "${i%.*}.mp3"; done # convert all opuss in this directory to mp3s at 320kbps'
alias aif-convert-mp3='for i in *.aif; do ffmpeg -i "$i" -ab 320k -map_metadata 0 -c:v copy "${i%.*}.mp3"; done # convert all aiffs in this directory to mp3s at 320kbps'

# load environment specifics if there are any (home config, work config)
test -e "${HOME}/.environment-specifics.zshrc" && source "${HOME}/.environment-specifics.zshrc" || true

[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"
