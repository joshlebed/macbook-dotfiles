# macbook-dotfiles

my ~/.config directory on a Macbook or other [\*nix](https://www.computerhope.com/jargon/num/nix.htm) system

## setup instructions

some files here are hardlinked system files from other locations. These commands will assume you clone this repo in `~/.config`:

```zsh
# clone repo
git clone https://github.com/joshlebed/macbook-dotfiles ~/.config

# install zsh
brew install zsh # on mac
apt install zsh # on ubuntu, debian, WSL

# install oh my zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# link zsh config
(test -e ~/.zshrc && mv ~/.zshrc ~/.zshrc.old); ln ~/.config/.zshrc ~/.zshrc

# link oh my zsh setup
ln ~/.config/zsh-themes/agnoster-custom.zsh-theme ~/.oh-my-zsh/themes/agnoster-custom.zsh-theme

# link slate config
(test -e ~/.slate.js && mv ~/.slate.js ~/.slate.js.old); ln ~/.config/.slate.js ~/.slate.js

# vscode setup (must install vscode first)
ln ~/.config/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
ln ~/.config/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json

# alfred setup (must install alfred first)
ln ~/.config/Alfred/Alfred.alfredpreferences ~/Library/Application\ Support/Alfred/Alfred.alfredpreferences

# intellij/IDEA setup (must install IDEA first)
ln ~/.config/IDEA/joshlebed-macOS-modified-keymap.xml /Users/lebedinj/Library/Application\ Support/JetBrains/IntelliJIdea2023.1/keymaps/joshlebed-macOS-modified-keymap.xml
ln /Users/lebedinj/Library/Application\ Support/JetBrains/IntelliJIdea2023.1/keymaps/joshlebed-macOS-modified-keymap.xml ~/.config/IDEA/joshlebed-macOS-modified-keymap.xml
```

## linux tools

[zsh](https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH): replacement for bash

[ohmyzsh](https://github.com/ohmyzsh/ohmyzsh): extension for managing zsh

## macbook tools

[karabiner-elements](https://karabiner-elements.pqrs.org/): keybindings

[keyboard maestro](https://www.keyboardmaestro.com/main/): hotkeys and automation

[slate](https://github.com/jigish/slate): directional focus for windows

[rectangle](https://rectangleapp.com/): move windows left and right

[amethyst](https://ianyh.com/amethyst/): move windows between spaces ([v0.15.6](https://github.com/ianyh/Amethyst/releases/tag/v0.15.6) until [multi monitor bug](https://github.com/ianyh/Amethyst/issues/1436) is fixed)

[limelight](https://github.com/koekeishiya/limelight): highlight focused window

[alfred](https://www.alfredapp.com/): replace spotlight (find and open things)

maybe [raycast](https://www.raycast.com/)? replace spotlight/alfred

[contexts](https://contexts.co/): replace alt-tab (switch between windows)

[bartender](https://www.macbartender.com/Bartender4/): to hide menu bar icons

[iterm](https://iterm2.com/): replace terminal

[brew](https://brew.sh/): package manager

[ddcctl](https://github.com/kfix/ddcctl): control external monitor brightness

[backup and sync](https://www.google.com/drive/download/): google drive sync

[vscode](https://code.visualstudio.com/): text editor and IDE

[finicky](https://github.com/johnste/finicky): link redirector (for AWS stuff)

## windows tools

[windows terminal](https://github.com/microsoft/terminal): replacement terminal emulator for windows

[vscode](https://code.visualstudio.com/): text editor and IDE

[autohotkey](https://www.autohotkey.com/): keybindings and window management

TODO: add AHK config somewhere

## chrome extensions

[google search keyboard shortcuts](https://chrome.google.com/webstore/detail/google-search-keyboard-sh/iobmefdldoplhmonnnkchglfdeepnfhd) - navigate google search results with keyboard

[notifier for github](https://chrome.google.com/webstore/detail/notifier-for-github/lmjdlojahmbbcodnpecnjnmlddbkjhnn) - github notifications

[tab to window/popup - keyboard shortcut](https://chrome.google.com/webstore/detail/tab-to-windowpopup-keyboa/adbkphmimfcaeonicpmamfddbbnphikh) - cmd+shift+p to pop a tab into a new window

[duplicate tab shortcut](https://chrome.google.com/webstore/detail/duplicate-tab-shortcut/klehggjefofgiajjfpoebdidnpjmljhb) - cmd+d to duplicate a tab

[bitwarden](https://chrome.google.com/webstore/detail/bitwarden-free-password-m/nngceckbapebfimnlniiiahkandclblb) - password management

[uBlock origin](https://chrome.google.com/webstore/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm) - adblocker

[dark reader](https://chrome.google.com/webstore/detail/dark-reader/eimadpbcbfnmbkopoojfekhnkhdbieeh) - to force dark mode
