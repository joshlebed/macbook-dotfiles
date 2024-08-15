#!/bin/bash

# TODO: maybe make this rely on zsh or bash 4+, or figure out a way to make this code work with spaces in file paths

# NOTE: ~ expansion won't work for some of these commands, so use ${HOME}
for SOURCE_TARGET_PAIR in \
  "${HOME}/.config/vscode/settings.json|${HOME}/Library/Application Support/Code/User/settings.json" \
  "${HOME}/.config/vscode/settings.json|${HOME}/Library/Application Support/Cursor/User/settings.json" \
  "${HOME}/.config/vscode/keybindings.json|${HOME}/Library/Application Support/Code/User/keybindings.json" \
  "${HOME}/.config/vscode/keybindings.json|${HOME}/Library/Application Support/Cursor/User/keybindings.json"

do
    IFS='|' read -r SOURCE TARGET <<< "$SOURCE_TARGET_PAIR"
    echo "SOURCE: $SOURCE"
    echo "TARGET: $TARGET"
    # exit 0
    # SOURCE="${HOME}/.config/vscode/settings.json"
    # TARGET="${HOME}/Library/Application Support/Code/User/settings.json"
    # SOURCE="${HOME}/.config/vscode/keybindings.json"
    # TARGET="${HOME}/Library/Application Support/Code/User/keybindings.json"

    test -e "$TARGET" && echo file found || echo file not found
    test -e "$TARGET.old" && echo backup found || echo backup not found

    test -e "$TARGET" && (
      test -e "$TARGET.old" && (
        echo removing old backup && rm "$TARGET.old"
      ) || echo no old backup found
      echo making new backup
      cp "$TARGET" "$TARGET.old"
      rm "$TARGET"
    )
    echo linking source to target
    ln -s "$SOURCE" "$TARGET"
    chflags nouchg "$TARGET"
done
