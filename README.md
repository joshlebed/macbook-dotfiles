# macbook-dotfiles

my ~/.config directory on a Macbook or other
[\*nix](https://www.computerhope.com/jargon/num/nix.htm) system

## setup instructions

some files here are hardlinked system files from other locations. These commands
will assume you clone this repo in `~/.config`:

on debian/ubuntu (apt-get):

```zsh
# set up brew, git, zsh, and omz
sudo apt-get update
sudo apt-get install git
git clone https://github.com/joshlebed/macbook-dotfiles ~/.config # clone this repo
sudo apt install zsh
(test -e ~/.zshrc && mv ~/.zshrc ~/.zshrc.old); ln ~/.config/.zshrc ~/.zshrc # link zsh config
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" # install omz
ln -s ~/.config/zsh-themes/agnoster-custom.zsh-theme ~/.oh-my-zsh/themes/agnoster-custom.zsh-theme # link omz theme
sudo apt install fzf
```

on macOS:

```zsh
git clone https://github.com/joshlebed/macbook-dotfiles ~/.config # clone this repo

# install shell
scripts/install_zsh_and_omz.sh

# install other tools
scripts/brew_install_all.sh

# symlink and lock config files - vscode settings, vscode keybindings
# TODO: maybe make this rely on zsh or bash 4+, or figure out a way to make this code work with spaces in file paths
scripts/symlink_config_files.sh

# hardlink config files - slate, finicky
scripts/hardlink_config_files.sh

# some config files need to be copied - contexts
scripts/copy_config_files.sh
# use this script to upload a new config or change a config for a stubborn program
scripts/save_initial_config_files.sh
```

sync keyboard maestro settings: File -> Start Syncing Macros -> select
km_macros.kmsync from this repo sync iterm settings: Preferences -> General ->
Preferences -> Load preferences from a custom folder or URL -> ~/.config/iterm2
install slate manually from here:
https://github.com/jigish/slate/blob/master/build/Release/Slate.dmg set up
google drive manually set up ticktick manually

### cursor setup

- install 'code' command
- import VS Code extensions and settings

### finicky setup

- see .finicky.js for config
- see .finicky_env_constants.js for browser profiles

## linux tools

[zsh](https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH): replacement for
bash

[ohmyzsh](https://github.com/ohmyzsh/ohmyzsh): extension for managing zsh

## macbook tools

[karabiner-elements](https://karabiner-elements.pqrs.org/): keybindings

[keyboard maestro](https://www.keyboardmaestro.com/main/): hotkeys and
automation

[slate](https://github.com/jigish/slate): directional focus for windows

[rectangle](https://rectangleapp.com/): move windows left and right

[amethyst](https://ianyh.com/amethyst/): move windows between spaces
([v0.15.6](https://github.com/ianyh/Amethyst/releases/tag/v0.15.6) until
[multi monitor bug](https://github.com/ianyh/Amethyst/issues/1436) is fixed)

[limelight](https://github.com/koekeishiya/limelight): highlight focused
window - TODO: this got taken down, find a replacement - currently using
HazeOver, tbd if it's worth it

[raycast](https://www.raycast.com/)? replace spotlight/alfred

[contexts](https://contexts.co/): replace alt-tab (switch between windows)

[bartender](https://www.macbartender.com/Bartender4/): to hide menu bar icons

[iterm](https://iterm2.com/): replace terminal

[brew](https://brew.sh/): package manager

[ddcctl](https://github.com/kfix/ddcctl): control external monitor brightness

[backup and sync](https://www.google.com/drive/download/): google drive sync

[vscode](https://code.visualstudio.com/): text editor and IDE

[cursor](https://www.cursor.com/): vscode with AI

[intellij](https://www.jetbrains.com/idea/): java IDE

[finicky](https://github.com/johnste/finicky): link redirector (for AWS stuff)

## windows tools

[windows terminal](https://github.com/microsoft/terminal): replacement terminal
emulator for windows

[chocolatey](https://chocolatey.org/install#individual): package manager

[vscode](https://code.visualstudio.com/): text editor and IDE

[autohotkey](https://www.autohotkey.com/): keybindings and window management

TODO: add AHK config somewhere

## chrome extensions

[google search keyboard shortcuts](https://chrome.google.com/webstore/detail/google-search-keyboard-sh/iobmefdldoplhmonnnkchglfdeepnfhd) -
navigate google search results with keyboard

[notifier for github](https://chrome.google.com/webstore/detail/notifier-for-github/lmjdlojahmbbcodnpecnjnmlddbkjhnn) -
github notifications

[tab to window/popup - keyboard shortcut](https://chrome.google.com/webstore/detail/tab-to-windowpopup-keyboa/adbkphmimfcaeonicpmamfddbbnphikh) -
cmd+shift+p to pop a tab into a new window

[duplicate tab shortcut](https://chrome.google.com/webstore/detail/duplicate-tab-shortcut/klehggjefofgiajjfpoebdidnpjmljhb) -
cmd+d to duplicate a tab

[bitwarden](https://chrome.google.com/webstore/detail/bitwarden-free-password-m/nngceckbapebfimnlniiiahkandclblb) -
password management

[uBlock origin](https://chrome.google.com/webstore/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm) -
adblocker

[dark reader](https://chrome.google.com/webstore/detail/dark-reader/eimadpbcbfnmbkopoojfekhnkhdbieeh) -
to force dark mode

[web scrobbler](https://chromewebstore.google.com/detail/web-scrobbler/hhinaapppaileiechjoiifaancjggfjm?pli=1) -
for last.fm

# TODO: switch from slate to one of these:

https://github.com/tmandry/Swindler https://github.com/koekeishiya/yabai yabai
looks like a good option
https://github.com/koekeishiya/yabai/blob/master/doc/yabai.asciidoc#window
