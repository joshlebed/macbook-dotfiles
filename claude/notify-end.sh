#!/bin/bash
# ~/.config/claude/scripts/notify-end.sh
#
# To install terminal-notifier for better notifications:
#   brew install terminal-notifier
#
# terminal-notifier provides better notification control with click actions

# =============================================================================
# CONFIGURATION: Choose what happens when clicking the notification
# =============================================================================
# Uncomment ONE of the following CLICK_ACTION options:

# Option 0: Just dismiss the notification (no other action)
# CLICK_ACTION="dismiss"
# CLICK_VALUE=""

# Option 1: Focus Terminal app
# CLICK_ACTION="activate"
# CLICK_VALUE="com.apple.Terminal"

# Option 2: Focus iTerm2 (default - detected you have iTerm installed)
CLICK_ACTION="activate"
CLICK_VALUE="com.googlecode.iterm2"

# Option 3: Open session directory in Finder
# CLICK_ACTION="open"
# CLICK_VALUE="file://$(pwd)"

# Option 4: Open session directory in VS Code
# CLICK_ACTION="execute"
# CLICK_VALUE="code \"$(pwd)\""

# Option 5: Custom command (example: play a sound and focus Terminal)
# CLICK_ACTION="execute"
# CLICK_VALUE="afplay /System/Library/Sounds/Ping.aiff && open -a Terminal"

# =============================================================================

# Read hook Input data from standard input
INPUT=$(cat)
# Get current session directory name (hooks run in the same directory as the session)
SESSION_DIR=$(basename "$(pwd)")
SESSION_PATH="$(pwd)"
# Extract transcript_path
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path')

echo "INPUT: $INPUT"
echo "SESSION_DIR: $SESSION_DIR"
echo "TRANSCRIPT_PATH: $TRANSCRIPT_PATH"

# If transcript_path exists, get the latest assistant message
if [ -f "$TRANSCRIPT_PATH" ]; then
    MSG=$(tail -10 "$TRANSCRIPT_PATH" | \
          jq -r 'select(.message.role == "assistant") | .message.content[0].text' | \
          tail -1 | \
          tr '\n' ' ' | \
          cut -c1-60)
    MSG=${MSG:-"Task completed...1"}
else
    MSG="Task completed...2"
fi

# Display notification
echo "MSG: $MSG"

# Check if terminal-notifier is available
if command -v terminal-notifier &> /dev/null; then
    # Use terminal-notifier for better notification experience
    # Build the base command
    NOTIFIER_CMD="terminal-notifier"
    NOTIFIER_CMD="$NOTIFIER_CMD -title \"ClaudeCode (${SESSION_DIR}) Task Done\""
    NOTIFIER_CMD="$NOTIFIER_CMD -message \"${MSG}\""
    NOTIFIER_CMD="$NOTIFIER_CMD -sound Glass"
    NOTIFIER_CMD="$NOTIFIER_CMD -group \"claude-code-${SESSION_DIR}\""
    NOTIFIER_CMD="$NOTIFIER_CMD -ignoreDnD"

    # Add click action based on configuration
    case "$CLICK_ACTION" in
        "dismiss")
            # Just dismiss the notification, no other action
            # No additional flags needed - clicking will dismiss
            ;;
        "activate")
            # Activate an application by bundle ID
            NOTIFIER_CMD="$NOTIFIER_CMD -activate \"$CLICK_VALUE\""
            ;;
        "open")
            # Open a URL or file
            # If CLICK_VALUE contains $(pwd), substitute it with the actual path
            ACTUAL_VALUE=$(echo "$CLICK_VALUE" | sed "s|\$(pwd)|$SESSION_PATH|g")
            NOTIFIER_CMD="$NOTIFIER_CMD -open \"$ACTUAL_VALUE\""
            ;;
        "execute")
            # Execute a shell command
            # If CLICK_VALUE contains $(pwd), substitute it with the actual path
            ACTUAL_VALUE=$(echo "$CLICK_VALUE" | sed "s|\$(pwd)|$SESSION_PATH|g")
            NOTIFIER_CMD="$NOTIFIER_CMD -execute \"$ACTUAL_VALUE\""
            ;;
        *)
            # Default: just show notification without click action
            ;;
    esac

    # Execute the notification command
    eval "$NOTIFIER_CMD"
else
    # Fallback to osascript if terminal-notifier is not installed
    # Note: osascript notifications have limitations:
    # - Stay until manually dismissed
    # - May open Script Editor when clicked
    # Install terminal-notifier with: brew install terminal-notifier
    osascript <<EOF
display notification "${MSG}" with title "ClaudeCode (${SESSION_DIR}) Task Done" sound name "Glass"
EOF
fi