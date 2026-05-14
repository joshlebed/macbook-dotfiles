#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Quote
# @raycast.mode silent
# @raycast.packageName Text

# Optional parameters:
# @raycast.icon 💬
# @raycast.description Wrap clipboard in a triple-backtick code block and paste into the frontmost app
# @raycast.author joshlebed
# @raycast.authorURL https://github.com/joshlebed

original="$(pbpaste)"

osascript - "$original" <<'APPLESCRIPT'
use framework "AppKit"
use scripting additions

on run argv
    set theOriginal to item 1 of argv
    set LF to linefeed
    set fence to "```"
    set theWrapped to LF & fence & LF & theOriginal & LF & fence & LF & LF

    set pb to current application's NSPasteboard's generalPasteboard()

    pb's clearContents()
    pb's setString:theWrapped forType:"public.utf8-plain-text"
    pb's setString:"" forType:"org.nspasteboard.ConcealedType"
    pb's setString:"" forType:"org.nspasteboard.TransientType"

    tell application "System Events" to keystroke "v" using command down

    delay 0.1

    pb's clearContents()
    pb's setString:theOriginal forType:"public.utf8-plain-text"
    pb's setString:"" forType:"org.nspasteboard.ConcealedType"
    pb's setString:"" forType:"org.nspasteboard.TransientType"
end run
APPLESCRIPT
