#!/bin/bash

brew install zsh
(test -e ~/.zshrc && mv ~/.zshrc ~/.zshrc.old)
ln -s ~/.config/.zshrc ~/.zshrc                                                                 # link zsh config
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" # install omz
(test -e ~/.oh-my-zsh/themes/agnoster.zsh-theme && mv ~/.oh-my-zsh/themes/agnoster.zsh-theme ~/.oh-my-zsh/themes/agnoster.zsh-theme.old)
ln -s ~/.config/zsh-themes/agnoster.zsh-theme ~/.oh-my-zsh/themes/agnoster.zsh-theme # link omz theme
