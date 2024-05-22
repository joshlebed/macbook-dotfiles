#!/bin/bash

# NOTE: ~ expansion won't work for some of these commands, so use ${HOME}
for SOURCE_TARGET_PAIR in \
  "${HOME}/.config/.slate.js ${HOME}/.slate.js" \
  "${HOME}/.config/.finicky.js ${HOME}/.finicky.js" \

  # "${HOME}/.config/IDEA/joshlebed-macOS-modified-keymap.xml ${HOME}/Library/Application\ Support/JetBrains/IntelliJIdea2023.1/keymaps/joshlebed-macOS-modified-keymap.xml" \

do
    set -- $SOURCE_TARGET_PAIR # Convert the tuple into the param args $1 $2...
    SOURCE=$1
    TARGET=$2
    echo SOURCE: $SOURCE
    echo TARGET: $TARGET
    test -e $TARGET && (
      test -e $TARGET.old && (
        echo removing old backup && rm $TARGET.old
      ) || echo no old backup found
      echo making new backup
      mv $TARGET $TARGET.old
    )
    echo hard linking source to target
    ln $SOURCE $TARGET
done
