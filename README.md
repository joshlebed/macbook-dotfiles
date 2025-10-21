# macbook-dotfiles

my ~/.config directory on a Macbook or other
[\*nix](https://www.computerhope.com/jargon/num/nix.htm) system

## setup instructions

some files here are hardlinked system files from other locations. These commands
will assume you clone this repo in `~/.config`:

### Linux Setup (Debian/Ubuntu/Fedora/Alpine/Arch)

#### Quick Setup (Recommended)

**With sudo (full installation):**

```bash
curl -fsSL https://raw.githubusercontent.com/joshlebed/macbook-dotfiles/main/scripts/setup-linux-dev.sh | sudo bash
```

**Without sudo (limited installation):**

```bash
curl -fsSL https://raw.githubusercontent.com/joshlebed/macbook-dotfiles/main/scripts/setup-linux-dev.sh | bash
```

#### What the script does

**With sudo privileges:**

- ✅ Installs system packages (git, zsh, tmux, fzf, curl, wget, fonts)
- ✅ Configures system locale settings
- ✅ Sets zsh as your default shell
- ✅ Clones this dotfiles repository to ~/.config
- ✅ Installs Oh My Zsh with custom theme
- ✅ Creates all necessary symlinks
- ✅ Installs development tools (NVM, Node.js, Claude Code CLI, shell-ai/q)

**Without sudo privileges:**

- ⚠️ SKIPS system package installation (requires manual install)
- ⚠️ SKIPS system locale configuration
- ⚠️ SKIPS setting zsh as default shell
- ✅ Clones this dotfiles repository to ~/.config
- ✅ Installs Oh My Zsh with custom theme
- ✅ Creates all necessary symlinks
- ✅ Installs development tools (NVM, Node.js, Claude Code CLI, shell-ai/q)

The script will clearly inform you what was skipped and provide instructions for
completing the setup manually if needed.

**Claude Code Installation Methods:**
- With sudo + npm: Installs globally via `npm install -g @anthropic-ai/claude-code`
- Without sudo + npm: Installs to `~/.local` via npm with custom prefix
- Without npm: Falls back to `curl -fsSL https://claude.ai/install.sh | bash`

**shell-ai Installation:**
- Installs the `q` command directly from GitHub releases as a binary to `~/.local/bin/`
- No Python or pip dependencies required
- Works on x86_64 and aarch64 architectures

#### Manual Setup (Alternative)

If you prefer to set things up manually:

```bash
# Install required packages (needs sudo)
sudo apt-get update
sudo apt-get install git zsh tmux fzf curl wget fonts-powerline

# Clone this repository
git clone https://github.com/joshlebed/macbook-dotfiles ~/.config

# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Create symlinks
ln -sf ~/.config/.zshrc ~/.zshrc
ln -sf ~/.config/.tmux.conf ~/.tmux.conf
ln -sf ~/.config/zsh-themes/agnoster.zsh-theme ~/.oh-my-zsh/themes/agnoster.zsh-theme

# Set zsh as default shell (needs sudo)
sudo chsh -s $(which zsh) $USER
```

### macOS Setup

```zsh
git clone https://github.com/joshlebed/macbook-dotfiles ~/.config # clone this repo
# Includes configs for: zsh, tmux, slate, finicky, VS Code, iTerm2, and more

# install shell
scripts/install_zsh_and_omz.sh

# install other tools
scripts/brew_install_all.sh

# symlink and lock config files - vscode settings, vscode keybindings
# TODO: maybe make this rely on zsh or bash 4+, or figure out a way to make this code work with spaces in file paths
scripts/symlink_config_files.sh

# hardlink config files - slate, finicky, tmux
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

[tmux](https://github.com/tmux/tmux): terminal multiplexer for managing multiple
terminal sessions

## macbook tools

[karabiner-elements](https://karabiner-elements.pqrs.org/): keybindings

[keyboard maestro](https://www.keyboardmaestro.com/main/): hotkeys and
automation

[slate](https://github.com/jigish/slate): directional focus for windows

[rectangle](https://rectangleapp.com/): move windows left and right

[limelight](https://github.com/koekeishiya/limelight): highlight focused
window - TODO: this got taken down, find a replacement - currently using
HazeOver, tbd if it's worth it

[raycast](https://www.raycast.com/)? replace spotlight/alfred

[contexts](https://contexts.co/): replace alt-tab (switch between windows)

[bartender](https://www.macbartender.com/Bartender4/): to hide menu bar icons

[iterm](https://iterm2.com/): replace terminal

[tmux](https://github.com/tmux/tmux): terminal multiplexer for managing multiple
terminal sessions

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
