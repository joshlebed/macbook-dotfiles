#!/bin/bash

set -e  # Exit on error

# ============================================================================
# Homebrew Installation and Package Setup for macOS
# ============================================================================

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# ============================================================================
# Install Homebrew (if not already installed)
# ============================================================================

if command -v brew >/dev/null 2>&1; then
    log_info "Homebrew already installed"
else
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to PATH for Apple Silicon Macs
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    log_success "Homebrew installed"
fi

# ============================================================================
# CLI Tools (formulae)
# ============================================================================

log_info "Installing CLI tools..."

FORMULAE=(
    git
    gh
    fzf
    tmux
    node
    pnpm
    yarn
    nvm
    rye
    uv
    pipx
    rustup-init
)

for formula in "${FORMULAE[@]}"; do
    if brew list "$formula" &>/dev/null; then
        log_info "$formula already installed"
    else
        log_info "Installing $formula..."
        brew install "$formula"
    fi
done

# shell-ai from tap
if ! brew list shell-ai &>/dev/null; then
    brew tap ibigio/tap
    brew install shell-ai
else
    log_info "shell-ai already installed"
fi

# ============================================================================
# GUI Applications (casks)
# ============================================================================

log_info "Installing GUI applications..."

CASKS=(
    iterm2
    google-chrome
    visual-studio-code
    cursor
    font-fira-code
    karabiner-elements
    raycast
    rectangle
    contexts
    keyboard-maestro
    bartender
    logi-options-plus
    hazeover
    slack
    google-drive
    finicky
    ddcctl
    ticktick
    docker
    # intellij-idea
)

for cask in "${CASKS[@]}"; do
    if brew list --cask "$cask" &>/dev/null; then
        log_info "$cask already installed"
    else
        log_info "Installing $cask..."
        brew install --cask "$cask"
    fi
done

# ============================================================================
# Claude Code via npm (enables auto-updates)
# ============================================================================

log_info "Installing Claude Code via npm..."

if command -v npm >/dev/null 2>&1; then
    if npm list -g @anthropic-ai/claude-code &>/dev/null; then
        log_info "Claude Code already installed via npm"
    else
        log_info "Installing @anthropic-ai/claude-code..."
        npm install -g @anthropic-ai/claude-code
        log_success "Claude Code installed via npm"
    fi
else
    log_warning "npm not found, skipping Claude Code installation"
    log_info "Install Node.js first, then run: npm install -g @anthropic-ai/claude-code"
fi

log_success "All packages installed!"
