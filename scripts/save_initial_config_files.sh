#!/bin/bash

# NOTE: ~ expansion won't work for some of these commands, so use ${HOME}
for SOURCE_TARGET_PAIR in \
  "${HOME}/.config/preferences/com.contextsformac.Contexts.plist ${HOME}/Library/Preferences/com.contextsformac.Contexts.plist" \
  "${HOME}/.config/preferences/com.raycast.macos.plist ${HOME}/Library/Preferences/com.raycast.macos.plist" \

do
    set -- $SOURCE_TARGET_PAIR # Convert the tuple into the param args $1 $2...
    SOURCE=$1
    TARGET=$2
    echo SOURCE: $SOURCE
    echo TARGET: $TARGET
    echo copying target to source for initial source control
    cp $TARGET $SOURCE
done
