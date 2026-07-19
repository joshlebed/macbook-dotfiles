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

osascript <<'APPLESCRIPT'
use framework "AppKit"
use scripting additions

on run
    # Read the clipboard via NSPasteboard instead of pbpaste + argv: Raycast
    # runs scripts without a UTF-8 locale, so pbpaste emits MacRoman and
    # osascript fails to decode non-ASCII arguments (error -1700).
    set pb to current application's NSPasteboard's generalPasteboard()
    set theOriginalNS to pb's stringForType:"public.utf8-plain-text"
    if theOriginalNS is missing value then return
    set theOriginal to theOriginalNS as text
    set LF to linefeed
    set fence to "```"
    set theWrapped to LF & fence & LF & theOriginal & LF & fence & LF & LF

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
