#!/usr/bin/env bash
# Idempotent script to set up iTerm2 Python API environment
# This script can be run multiple times safely

set -e

ITERM2_DIR="$HOME/.iterm2"
VENV_DIR="$ITERM2_DIR/venv"
RUNPYTHON="$ITERM2_DIR/runpython"

echo "Setting up iTerm2 Python API environment..."

# Create .iterm2 directory if it doesn't exist
mkdir -p "$ITERM2_DIR"

# Create venv if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv "$VENV_DIR"
else
    echo "Virtual environment already exists."
fi

# Install/upgrade iterm2 module
echo "Installing/upgrading iterm2 module..."
"$VENV_DIR/bin/pip" install --upgrade iterm2 >/dev/null 2>&1

# Create runpython wrapper with auto-setup capability
echo "Creating runpython wrapper..."
cat > "$RUNPYTHON" <<'EOF'
#!/usr/bin/env bash
# Wrapper to run iTerm2 API scripts in the local venv
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Auto-setup if venv is missing
if [ ! -d "$DIR/venv" ]; then
    echo "Virtual environment not found. Running setup..."
    if [ -f "$DIR/setup-iterm2-api.sh" ]; then
        bash "$DIR/setup-iterm2-api.sh"
    else
        echo "Error: Setup script not found. Please run setup manually."
        exit 1
    fi
fi

# Check if iterm2 module is available
if ! "$DIR/venv/bin/python" -c "import iterm2" 2>/dev/null; then
    echo "iTerm2 module not found. Installing..."
    "$DIR/venv/bin/pip" install iterm2
fi

"$DIR/venv/bin/python" "$@"
EOF
chmod +x "$RUNPYTHON"

# Copy this setup script to .iterm2 for future auto-runs
if [ "$0" != "$ITERM2_DIR/setup-iterm2-api.sh" ]; then
    cp "$0" "$ITERM2_DIR/setup-iterm2-api.sh"
    chmod +x "$ITERM2_DIR/setup-iterm2-api.sh"
fi

# Test the setup
echo "Testing setup..."
if "$RUNPYTHON" -c "import iterm2; print('✅ iTerm2 module loaded successfully')" 2>/dev/null; then
    echo "✅ Setup complete! You can now run:"
    echo "  ~/.iterm2/runpython ~/.iterm2/it2api hotkey-window"
    echo ""
    echo "For convenience, add this alias to your ~/.zshrc:"
    echo "  alias it2hw='~/.iterm2/runpython ~/.iterm2/it2api hotkey-window'"

    # Check if alias already exists in .zshrc
    if [ -f "$HOME/.zshrc" ] && ! grep -q "alias it2hw=" "$HOME/.zshrc"; then
        echo ""
        echo "Would you like to add the alias automatically? (y/n)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            {
                echo ""
                echo "# iTerm2 hotkey window alias"
                echo "alias it2hw='~/.iterm2/runpython ~/.iterm2/it2api hotkey-window'"
            } >> "$HOME/.zshrc"
            echo "✅ Alias added to ~/.zshrc"
        fi
    fi
else
    echo "❌ Setup verification failed. Please check Python installation."
    exit 1
fi