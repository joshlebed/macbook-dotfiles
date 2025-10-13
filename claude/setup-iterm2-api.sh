#!/usr/bin/env bash
# Complete setup for Claude Code + iTerm2 integration
# Safe to run multiple times (idempotent)

set -e

ITERM2_DIR="$HOME/.iterm2"
VENV_DIR="$ITERM2_DIR/venv"
RUNPYTHON="$ITERM2_DIR/runpython"

echo "🚀 Setting up Claude Code + iTerm2 integration..."
echo ""

# Check for terminal-notifier
if ! command -v terminal-notifier &> /dev/null; then
    echo "📦 Installing terminal-notifier for clickable notifications..."
    if command -v brew &> /dev/null; then
        brew install terminal-notifier
    else
        echo "⚠️  Homebrew not found. Install it from https://brew.sh"
        echo "   Then run: brew install terminal-notifier"
    fi
else
    echo "✅ terminal-notifier already installed"
fi

# Create .iterm2 directory if it doesn't exist
mkdir -p "$ITERM2_DIR"

# Create venv if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    echo "📦 Creating Python virtual environment at ~/.iterm2/venv/..."
    python3 -m venv "$VENV_DIR"
else
    echo "✅ Virtual environment already exists"
fi

# Install/upgrade iterm2 module
echo "📦 Installing/upgrading iterm2 Python module..."
"$VENV_DIR/bin/pip" install --upgrade iterm2 >/dev/null 2>&1
echo "✅ iterm2 module ready"

# Create runpython wrapper with auto-setup capability
echo "📦 Creating runpython wrapper..."
cat > "$RUNPYTHON" <<'EOF'
#!/usr/bin/env bash
# Wrapper to run iTerm2 API scripts in the local venv
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Auto-setup if venv is missing
if [ ! -d "$DIR/venv" ]; then
    echo "⚠️ Virtual environment not found. Running setup..."
    if [ -f "$DIR/setup-iterm2-api.sh" ]; then
        bash "$DIR/setup-iterm2-api.sh"
    else
        echo "❌ Setup script not found. Please run:"
        echo "   bash ~/.config/claude/setup-iterm2-api.sh"
        exit 1
    fi
fi

# Check if iterm2 module is available
if ! "$DIR/venv/bin/python" -c "import iterm2" 2>/dev/null; then
    echo "📦 iTerm2 module not found. Installing..."
    "$DIR/venv/bin/pip" install iterm2
fi

"$DIR/venv/bin/python" "$@"
EOF
chmod +x "$RUNPYTHON"
echo "✅ runpython wrapper created"

# Copy this setup script to .iterm2 for future auto-runs
if [ "$0" != "$ITERM2_DIR/setup-iterm2-api.sh" ]; then
    cp "$0" "$ITERM2_DIR/setup-iterm2-api.sh"
    chmod +x "$ITERM2_DIR/setup-iterm2-api.sh"
fi

# Test the setup
echo ""
echo "🧪 Testing setup..."
if "$RUNPYTHON" -c "import iterm2" 2>/dev/null; then
    echo "✅ iTerm2 Python API ready"

    # Check if it2api exists
    if [ ! -f "$ITERM2_DIR/it2api" ]; then
        echo "⚠️  Note: ~/.iterm2/it2api script not found"
        echo "   iTerm2 will create it when you enable Python API support"
        echo "   Go to: iTerm2 → Preferences → General → Magic → Enable Python API"
    fi

    echo ""
    echo "✨ Setup complete!"
    echo ""
    echo "📝 Next steps:"
    echo "   1. Ensure iTerm2 hotkey window is configured:"
    echo "      iTerm2 → Preferences → Keys → Hotkey Window"
    echo ""
    echo "   2. Test the integration:"
    echo "      echo '{\"transcript_path\": \"/tmp/test\"}' | ~/.config/claude/notify-end.sh"
    echo ""
    echo "   3. Claude Code notifications will now open iTerm2 when clicked!"

    # Check if alias already exists in .zshrc
    if [ -f "$HOME/.zshrc" ] && ! grep -q "alias it2hw=" "$HOME/.zshrc"; then
        echo ""
        echo "💡 Add a handy alias? (y/n)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            {
                echo ""
                echo "# iTerm2 hotkey window alias"
                echo "alias it2hw='~/.iterm2/runpython ~/.iterm2/it2api hotkey-window'"
            } >> "$HOME/.zshrc"
            echo "✅ Added 'it2hw' alias to ~/.zshrc"
        fi
    fi
else
    echo "❌ Setup verification failed. Please check Python installation."
    echo "   Try: brew install python3"
    exit 1
fi