#!/bin/bash

set -e

# ============================================================================
# Install Zsh and Oh My Zsh
# ============================================================================
#
# Installs zsh and oh-my-zsh. Symlinks (.zshrc, theme) are handled separately
# by link-files.sh via config/file-mappings.conf.
#
# ============================================================================

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_skip() { echo -e "${BLUE}[SKIP]${NC} $1"; }

echo ""
log_info "Setting up Zsh and Oh My Zsh..."
echo ""

# ============================================================================
# Install Zsh
# ============================================================================

if command -v zsh >/dev/null 2>&1; then
    log_skip "Zsh already installed"
else
    log_info "Installing zsh via Homebrew..."
    brew install zsh
    log_success "Zsh installed"
fi

# ============================================================================
# Install Oh My Zsh
# ============================================================================

if [[ -d "${HOME}/.oh-my-zsh" ]]; then
    log_skip "Oh My Zsh already installed"
else
    log_info "Installing Oh My Zsh..."
    export RUNZSH=no      # Don't auto-launch zsh
    export CHSH=no        # Don't change shell (we handle this separately)
    export KEEP_ZSHRC=yes # Don't overwrite .zshrc
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    log_success "Oh My Zsh installed"
fi

echo ""
log_success "Zsh and Oh My Zsh ready!"
echo ""
