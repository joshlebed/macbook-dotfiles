# for new setup, hardlink this file (see readme)

# oh-my-zsh config
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"
DEFAULT_USER="joshlebed"
REPORTTIME=2
plugins=(git)
source $ZSH/oh-my-zsh.sh
export EDITOR=vim

if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS-specific
  export VISUAL=code
  export NEXT_EDITOR=code
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Linux-specific
  export VISUAL=vim
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
export ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=1
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh" || true

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


# git aliases
alias gs="git status"

# Graphite CLI wrapper - auto-switch profile based on repo
gt() {
    local email=$(git config user.email 2>/dev/null)
    if [[ "$email" == "josh.lebedinsky@keru.ai" ]]; then
        GRAPHITE_PROFILE=kepler command gt "$@"
    else
        command gt "$@"
    fi
}

# AWS CLI wrapper - auto-switch profile based on repo
aws() {
    local remote_url=$(git config --get remote.origin.url 2>/dev/null)
    if [[ "$remote_url" =~ joshlebed ]]; then
        AWS_PROFILE=josh-personal command aws "$@"
    else
        command aws "$@"
    fi
}

alias la="ls -a"
alias gc="git commit -m"
alias gch="git checkout"
alias gcb="git checkout -b"
alias gpp="git push --set-upstream origin"
alias config="cd ~/.config"
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
alias quicklinks-dev="code ~/.config/ ~/.config/raycast/quicklinks/quicklinks-generator.js ~/.config/raycast/README.md && quicklinks-build"

alias kill-bluetooth="sudo pkill bluetoothd"

# Function to copy the output of the last command to the clipboard
alias copylast='(eval $(fc -ln -1) &> /dev/null | pbcopy)'
alias copy='copylast'
p() {
  builtin pwd -P | tee >(tr -d '\n' | pbcopy)
}
c() {
  local dirs=(~/code ~/code/scripts)  # edit this list
  local selected
  local stat_cmd
  if [[ "$OSTYPE" == "darwin"* ]]; then
    stat_cmd="stat -f '%m %N'"
  else
    stat_cmd="stat -c '%Y %n'"
  fi
  selected=$(eval "$stat_cmd" ${^dirs}/*/.git/logs/HEAD(N) 2>/dev/null \
    | sort -rn \
    | cut -d' ' -f2- \
    | sed 's|/\.git/logs/HEAD||' \
    | fzf --height=40% --reverse --border --delimiter='/' --with-nth=-1) \
    && cd "$selected"
}
alias e="exit"

# SSH + tmux integration for iTerm2
# Usage: ssh-tmux-iterm hostname [session-name]
ssh-tmux-iterm() {
  local host="$1"
  local session="${2:-main}"

  if [[ -z "$host" ]]; then
    echo "Usage: ssh-tmux-iterm hostname [session-name]"
    return 1
  fi

  ssh -t "$host" "tmux -CC new -A -s $session"
}

# pnpm
export PNPM_HOME="/Users/joshlebed/Library/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Added by LM Studio CLI (lms)
[[ -f "$HOME/.lmstudio/bin" ]] && export PATH="$HOME/.lmstudio/bin:$PATH"
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

# TODO: move other stuff from above to dev-aliases.sh
test -e "${HOME}/.config/dev-aliases.sh" && source "${HOME}/.config/dev-aliases.sh" || true
# load environment specifics if there are any (home config, work config)
test -e "${HOME}/.environment-specifics.zshrc" && source "${HOME}/.environment-specifics.zshrc" || true

[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"
[[ -f "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

alias python="python3"
alias timeout=gtimeout
alias aic=oco

#compdef gt
###-begin-gt-completions-###
#
# yargs command completion script
#
# Installation: gt completion >> ~/.zshrc
#    or gt completion >> ~/.zprofile on OSX.
#
_gt_yargs_completions() {
  local reply
  local si=$IFS
  IFS=$'
' reply=($(COMP_CWORD="$((CURRENT - 1))" COMP_LINE="$BUFFER" COMP_POINT="$CURSOR" gt --get-yargs-completions "${words[@]}"))
  IFS=$si
  _describe 'values' reply
}
compdef _gt_yargs_completions gt
###-end-gt-completions-###
