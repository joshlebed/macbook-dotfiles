#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Smart Search
# @raycast.mode silent
# @raycast.packageName Search

# Optional parameters:
# @raycast.icon 🔍
# @raycast.description Copy selection, then open Linear / GitHub / URL / Google Search based on its content
# @raycast.author joshlebed
# @raycast.authorURL https://github.com/joshlebed

# Documentation:
# Bind to cmd+g in Raycast (and disable the old KM cmd+g macro). On trigger:
#   1. Copies the current selection via cmd+c
#   2. Routes the clipboard contents:
#        https?://...           -> open as URL
#        NS-790 (whitelisted prefixes) -> linear.app/<workspace>/issue/<ID>
#        #4953                  -> app.graphite.com/github/pr/<default repo>/4953
#        domain.tld[/path]      -> open as URL (auto-prefixes https://)
#        scheme:rest            -> open in the registered app (spotify:, slack://, mailto:, ...)
#        anything else          -> Google search

# Raycast runs scripts without a UTF-8 locale; without this, pbpaste
# transcodes non-ASCII clipboard text to MacRoman (and drops emoji).
export LC_CTYPE=UTF-8

LINEAR_WORKSPACE="niteshift"
LINEAR_TEAM_PREFIXES="NS" # pipe-separated whitelist, e.g. "NS|ENG"
GITHUB_DEFAULT_REPO="niteshiftdev/niteshift"

osascript -e 'tell application "System Events" to keystroke "c" using command down'
sleep 0.15

input="$(pbpaste | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

if [ -z "$input" ]; then
    echo "No selection"
    exit 0
fi

# 1. URL with explicit scheme
if [[ "$input" =~ ^https?://[^[:space:]]+$ ]]; then
    open "$input"
    echo "Opening URL"
    exit 0
fi

# 2. Linear ticket (whitelisted team prefixes only, normalized to uppercase)
ticket="$(echo "$input" | tr '[:lower:]' '[:upper:]')"
if [[ "$ticket" =~ ^(${LINEAR_TEAM_PREFIXES})-[0-9]+$ ]]; then
    open "https://linear.app/${LINEAR_WORKSPACE}/issue/${ticket}"
    echo "Opening Linear: $ticket"
    exit 0
fi

# 3. GitHub PR/issue in the default repo -> open in Graphite
if [[ "$input" =~ ^#[0-9]+$ ]]; then
    num="${input#\#}"
    open "https://app.graphite.com/github/pr/${GITHUB_DEFAULT_REPO}/${num}"
    echo "Opening Graphite: #${num}"
    exit 0
fi

# 4. Bare domain or domain/path (no scheme, no spaces)
if [[ "$input" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*\.[a-zA-Z]{2,}(/[^[:space:]]*)?$ ]]; then
    open "https://$input"
    echo "Opening URL (added https://)"
    exit 0
fi

# 5. Custom URL scheme (no spaces) -> let macOS open the registered app.
#    Restores the old "paste into Chrome's address bar" behavior for things like
#    spotify:track:..., slack://..., zoommtg://..., mailto:..., vscode://...
#    `open` exits non-zero when no app claims the scheme, so we fall through to Google.
if [[ "$input" =~ ^[a-zA-Z][a-zA-Z0-9+.-]*:[^[:space:]]+$ ]]; then
    if open "$input" 2>/dev/null; then
        echo "Opening: $input"
        exit 0
    fi
fi

# 6. Fallback: Google search
query="$(python3 -c "import sys, urllib.parse; print(urllib.parse.quote_plus(sys.argv[1]))" "$input")"
open "https://www.google.com/search?q=${query}"
echo "Searching Google"
