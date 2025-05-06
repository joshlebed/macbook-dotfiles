#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Unpack URL
# @raycast.mode silent
# @raycast.packageName Unpack URL

# Optional parameters:
# @raycast.icon images/Message.png

# Documentation:
# @raycast.description separate out URL params
# @raycast.author joshlebed
# @raycast.authorURL https://github.com/joshlebed

# -----------------------------------------

# Get the URL from clipboard
url=$(pbpaste)

# find this regex:
# (.)([&?])

# replace with:
# $1
# $2

modified_url=$(echo "$url" | sed 's/\([^&?]\)\([&?]\)/\1\n/g')

# replace '=' with ' = '
modified_url=$(echo "$modified_url" | sed 's/=/ = /g')

# Copy the modified URL back to clipboard
echo "$modified_url" | pbcopy

echo "URL unpacked: question marks replaced with slashes"
