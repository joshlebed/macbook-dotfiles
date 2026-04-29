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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"
BREWFILE="$CONFIG_DIR/Brewfile"

FAILURES=()
SKIP_APPS=false

show_help() {
    cat << EOF
Homebrew Installation and Package Setup for macOS

Usage: $(basename "$0") [OPTIONS]

Options:
    -h, --help       Show this help message
    --skip-apps      Skip GUI application casks

Uses: $BREWFILE

EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        --skip-apps)
            SKIP_APPS=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

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
# Packages from Brewfile
# ============================================================================

if [[ ! -f "$BREWFILE" ]]; then
    log_error "Brewfile not found: $BREWFILE"
    exit 1
fi

bundle_file="$BREWFILE"
temp_brewfile=""

if [[ "$SKIP_APPS" == true ]]; then
    log_warning "Skipping GUI applications (--skip-apps)"
    temp_brewfile=$(mktemp)
    awk '$1 != "cask" { print }' "$BREWFILE" > "$temp_brewfile"
    bundle_file="$temp_brewfile"
fi

log_info "Installing Homebrew packages from $(basename "$BREWFILE")..."
if ! brew bundle --file "$bundle_file" --no-upgrade; then
    log_error "Failed to install Homebrew packages from Brewfile"
    FAILURES+=("brew-bundle")
fi

[[ -n "$temp_brewfile" ]] && rm -f "$temp_brewfile"

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
