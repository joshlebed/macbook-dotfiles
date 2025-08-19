#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Pack/Unpack URL
# @raycast.mode silent
# @raycast.packageName Pack/Unpack URL

# Optional parameters:
# @raycast.icon 🔗

# Documentation:
# @raycast.description Toggle between packed and unpacked URL format
# @raycast.author joshlebed
# @raycast.authorURL https://github.com/joshlebed

# -----------------------------------------

# Get the content from clipboard
input=$(pbpaste)

# Check if input contains newlines (unpacked format) or URL parameters (packed format)
# Count the number of lines - if more than 1, it's unpacked format
if [ "$(echo "$input" | wc -l)" -gt 1 ]; then
    # Input has newlines - it's unpacked format, so pack it
    
    # Process the input line by line
    first_line=true
    result=""
    while IFS= read -r line; do
        if [ "$first_line" = true ]; then
            # First line is the base URL
            result="$line"
            first_line=false
        elif [ -n "$line" ]; then
            # Remove spaces around = and determine separator
            param="${line// = /=}"
            
            # Check if this is the first parameter (use ?) or additional (use &)
            if [[ "$result" == *"?"* ]]; then
                result="${result}&${param}"
            else
                result="${result}?${param}"
            fi
        fi
    done <<< "$input"
    
    # Copy the packed URL back to clipboard
    echo "$result" | pbcopy
    echo "URL packed: parameters combined into single URL"
    
else
    # No newlines - it's packed format, so unpack it
    
    # Separate URL and parameters with newlines
    modified_url=$(echo "$input" | sed 's/\([^&?]\)\([&?]\)/\1\n/g')
    
    # Add spaces around '=' for readability
    modified_url=$(echo "$modified_url" | sed 's/=/ = /g')
    
    # Copy the unpacked URL back to clipboard
    echo "$modified_url" | pbcopy
    echo "URL unpacked: parameters separated into readable format"
fi