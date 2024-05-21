#!/bin/bash

# NOTE: ~ expansion won't work for some of these commands, so use ${HOME}
for SOURCE_TARGET_PAIR in \
  "${HOME}/.config/preferences/com.contextsformac.Contexts.plist ${HOME}/Library/Preferences/com.contextsformac.Contexts.plist" \
  "${HOME}/.config/preferences/com.knollsoft.Rectangle.plist ${HOME}/Library/Preferences/com.knollsoft.Rectangle.plist" \
  "${HOME}/.config/preferences/com.amethyst.Amethyst.plist ${HOME}/Library/Preferences/com.amethyst.Amethyst.plist" \
  "${HOME}/.config/preferences/com.raycast.macos.plist ${HOME}/Library/Preferences/com.raycast.macos.plist" \
  "${HOME}/.config/preferences/com.surteesstudios.Bartender.plist ${HOME}/Library/Preferences/com.surteesstudios.Bartender.plist" \

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
    echo copying source to target
    cp $SOURCE $TARGET
done
