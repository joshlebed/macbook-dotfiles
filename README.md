# macbook-dotfiles

my ~/.config directory on a Macbook or other [\*nix](https://www.computerhope.com/jargon/num/nix.htm) system

## setup instructions

some files here are hardlinked system files from other locations. These commands will assume you clone this repo in `~/.config`:

on debian/ubuntu (apt-get):

```zsh
# set up brew, git, zsh, and omz
sudo apt-get update
sudo apt-get install git
git clone https://github.com/joshlebed/macbook-dotfiles ~/.config # clone this repo
apt install zsh
(test -e ~/.zshrc && mv ~/.zshrc ~/.zshrc.old); ln ~/.config/.zshrc ~/.zshrc # link zsh config
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" # install omz
ln ~/.config/zsh-themes/agnoster-custom.zsh-theme ~/.oh-my-zsh/themes/agnoster-custom.zsh-theme # link omz theme
```

on macOS:

```zsh
# set up brew, git, zsh, and omz
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" # install homebrew
brew install git
git clone https://github.com/joshlebed/macbook-dotfiles ~/.config # clone this repo
brew install zsh
(test -e ~/.zshrc && mv ~/.zshrc ~/.zshrc.old); ln ~/.config/.zshrc ~/.zshrc # link zsh config
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" # install omz
ln ~/.config/zsh-themes/agnoster-custom.zsh-theme ~/.oh-my-zsh/themes/agnoster-custom.zsh-theme # link omz theme

# install other tools
brew install --cask visual-studio-code
brew install --cask raycast
brew install --cask bartender
brew install --cask keyboard-maestro
brew install --cask amethyst
brew install --cask karabiner-elements
brew install --cask rectangle
brew install --cask contexts
brew install --cask iterm2
brew install --cask google-drive
brew install --cask intellij-idea
brew install --cask finicky
brew install ddcctl
# install slate manually

# sync preferences for tools
ln ~/.config/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json # link vscode settings
ln ~/.config/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json # link vscode keybindings
# sync raycast settings manually (TODO: sync dir ~/Library/Application Support/com.raycast.macos)
# sync bartender settings manually (TODO: sync dir)
# sync keyboard maestro settings by importing from .kmsync file in this repo
# sync amethyst settings manually (TODO: sync dir)
# karabiner config already synced in .config
# sync rectangle settings manually (TODO: sync dir)
# sync contexts settings manually (TODO: sync dir)
# point iterm at com.googlecode.iterm2.plist config if not automatic (TODO: update this readme if it is automatic)
# google drive needs setup wizard
ln ~/.config/IDEA/joshlebed-macOS-modified-keymap.xml /Users/lebedinj/Library/Application\ Support/JetBrains/IntelliJIdea2023.1/keymaps/joshlebed-macOS-modified-keymap.xml # intellij/IDEA config
(test -e ~/.slate.js && mv ~/.slate.js ~/.slate.js.old); ln ~/.config/.slate.js ~/.slate.js  # link slate config
(test -e ~/.finicky.js && mv ~/.finicky.js ~/.finicky.js.old); ln ~/.config/.finicky.js ~/.finicky.js  # link finicky config
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

[limelight](https://github.com/koekeishiya/limelight): highlight focused window - TODO: this got taken down, find a replacement

[raycast](https://www.raycast.com/)? replace spotlight/alfred

[contexts](https://contexts.co/): replace alt-tab (switch between windows)

[bartender](https://www.macbartender.com/Bartender4/): to hide menu bar icons

[iterm](https://iterm2.com/): replace terminal

[brew](https://brew.sh/): package manager

[ddcctl](https://github.com/kfix/ddcctl): control external monitor brightness

[backup and sync](https://www.google.com/drive/download/): google drive sync

[vscode](https://code.visualstudio.com/): text editor and IDE

[intellij](https://www.jetbrains.com/idea/): java IDE

[finicky](https://github.com/johnste/finicky): link redirector (for AWS stuff)

## windows tools

[windows terminal](https://github.com/microsoft/terminal): replacement terminal emulator for windows

[chocolatey](https://chocolatey.org/install#individual): package manager

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
