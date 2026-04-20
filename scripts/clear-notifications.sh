#!/bin/bash
# Clear ALL notifications on macOS 26 Tahoe
# Flow: open tray → click X menu → click "Clear All Notifications" → close tray
# If no notifications, just opens and closes tray harmlessly
# REQUIRES: Accessibility permissions for your terminal app

osascript -e '
tell application "System Events"
    -- 1. Open tray
    tell process "ControlCenter"
        click (first menu bar item of menu bar 1 whose description is "Clock")
    end tell
    -- delay 0.1

    tell process "NotificationCenter"
        -- 2. Find and click the X menu button
        set foundMenu to false
        set allElements to entire contents of window 1
        repeat with elem in allElements
            try
                if (class of elem as text) is "menu button" then
                    perform action "AXShowMenu" of elem
                    set foundMenu to true
                    exit repeat
                end if
            end try
        end repeat

        if foundMenu then
            -- delay 0.1

            -- 3. Click "Clear All Notifications"
            set allElements to entire contents of window 1
            repeat with elem in allElements
                try
                    if (name of elem as text) is "Clear All Notifications" then
                        perform action "AXPress" of elem
                        exit repeat
                    end if
                end try
            end repeat
        end if
    end tell

    -- 4. Close tray
    -- delay 0.1
    tell process "ControlCenter"
        click (first menu bar item of menu bar 1 whose description is "Clock")
    end tell
end tell
'
