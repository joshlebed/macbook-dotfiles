# macbook-dotfiles

my ~/.config directory on a Macbook.

## setup instructions

some files here are hardlinked system files from other locations. These commands will assume you clone this repo in `~/.config`:

```zsh
git clone https://github.com/joshlebed/macbook-dotfiles ~/.config
ln ~/.config/.zshrc ~/.zshrc
ln ~/.config/.slate.js ~/.slate.js
```

### oh my zsh setup

```zsh
curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
ln ~/.config/zsh-themes/agnoster-custom.zsh-theme ~/.oh-my-zsh/themes/agnoster-custom.zsh-theme
```

### vscode setup

```
ln -s ~/.config/vscode/keybindings.json '~/Library/Application Support/Code/User/keybindings.json'
ln -s ~/.config/vscode/settings.json '~/Library/Application Support/Code/User/settings.json'
```


### my ~/.config directory on a Macbook.
