#!/bin/bash
# Claude Code notification with iTerm2 hotkey window integration
# Click notification → Opens iTerm2 hotkey window

# Check dependencies and auto-setup if needed
if [ ! -f "$HOME/.iterm2/runpython" ] || [ ! -f "$HOME/.iterm2/it2api" ]; then
    echo "⚠️ iTerm2 API not set up. Running setup..."
    if [ -f "$HOME/.config/claude/setup-iterm2-api.sh" ]; then
        bash "$HOME/.config/claude/setup-iterm2-api.sh"
    else
        echo "❌ Setup script not found. Please run:"
        echo "   bash ~/.config/claude/setup-iterm2-api.sh"
        exit 1
    fi
fi

# Read input and extract session info
INPUT=$(cat)
SESSION_DIR=$(basename "$(pwd)")
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path')

# Get the latest assistant message for notification text (max 60 chars)
if [ -f "$TRANSCRIPT_PATH" ]; then
    MSG=$(tail -10 "$TRANSCRIPT_PATH" | \
          jq -r 'select(.message.role == "assistant") | .message.content[0].text' | \
          tail -1 | \
          tr '\n' ' ' | \
          cut -c1-60)
fi
MSG=${MSG:-"Task completed"}

# Send notification
if command -v terminal-notifier &> /dev/null; then
    # Clickable notification that opens iTerm2 hotkey window
    # curretly does nothing
    
    terminal-notifier \
        -title "Claude Code (${SESSION_DIR})" \
        -message "${MSG}" \
        -sound Glass \
        -group "claude-code-${SESSION_DIR}" \
        -ignoreDnD \
        -execute ""
else
    # Basic notification (no click action)
    osascript -e "display notification \"${MSG}\" with title \"Claude Code (${SESSION_DIR})\" sound name \"Glass\""
    echo "💡 For clickable notifications: brew install terminal-notifier"
fi