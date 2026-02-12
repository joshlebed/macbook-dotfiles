#!/bin/bash

# ============================================================================
# Homebrew Installation and Package Setup for macOS
# ============================================================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

FAILURES=()

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
        if ! brew install "$formula"; then
            log_error "Failed to install $formula"
            FAILURES+=("$formula")
        fi
    fi
done

# shell-ai from tap
if ! brew list shell-ai &>/dev/null; then
    if ! (brew tap ibigio/tap && brew install shell-ai); then
        log_error "Failed to install shell-ai"
        FAILURES+=("shell-ai")
    fi
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
    ticktick
    docker
    # intellij-idea
)

for cask in "${CASKS[@]}"; do
    if brew list --cask "$cask" &>/dev/null; then
        log_info "$cask already installed"
    else
        log_info "Installing $cask..."
        if ! brew install --cask "$cask"; then
            log_error "Failed to install $cask"
            FAILURES+=("$cask")
        fi
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
        if npm install -g @anthropic-ai/claude-code; then
            log_success "Claude Code installed via npm"
        else
            log_error "Failed to install Claude Code via npm"
            FAILURES+=("claude-code")
        fi
    fi
else
    log_warning "npm not found, skipping Claude Code installation"
    log_info "Install Node.js first, then run: npm install -g @anthropic-ai/claude-code"
fi

if [[ ${#FAILURES[@]} -gt 0 ]]; then
    echo ""
    log_warning "The following packages failed to install:"
    for pkg in "${FAILURES[@]}"; do
        echo "  - $pkg"
    done
    echo ""
    log_warning "You may need to install these manually."
    exit 1
else
    log_success "All packages installed!"
fi
