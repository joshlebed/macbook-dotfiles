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

# ============================================================================
# SUDO
# ============================================================================
#
# Several casks are pkg installers (Microsoft Office, Zoom, OneDrive, Okta
# Verify, Malwarebytes) and each shells out to sudo. macOS caches a sudo
# credential for only 5 minutes (timestamp_timeout) and ties it to the terminal
# session (tty_tickets), so a long bundle re-prompts over and over.
#
# Ask once up front, then refresh in the background for the life of this script.
# Nothing is written to /etc/sudoers: the credential still expires normally once
# the script exits, so this changes how often you are asked, not what sudo will
# allow.

SUDO_KEEPALIVE_PID=""

start_sudo_keepalive() {
    if ! [[ -t 0 ]]; then
        log_warning "Not running in a terminal — sudo can't prompt."
        log_warning "pkg-based casks will fail. Run this from a real terminal."
        return 1
    fi

    log_info "Some casks are pkg installers and need your password."
    log_info "Asking once now and keeping it alive, rather than a dozen prompts."
    if ! sudo -v; then
        log_warning "Couldn't cache sudo — brew will prompt per package."
        return 1
    fi

    # Refresh inside the timeout window until this script exits.
    while true; do
        sudo -n true 2>/dev/null || exit
        sleep 50
        kill -0 "$$" 2>/dev/null || exit
    done &
    SUDO_KEEPALIVE_PID=$!
    log_success "sudo cached; you shouldn't be asked again during this run."
}

cleanup() {
    [[ -n "$SUDO_KEEPALIVE_PID" ]] && kill "$SUDO_KEEPALIVE_PID" 2>/dev/null
    [[ -n "${temp_brewfile:-}" ]] && rm -f "$temp_brewfile"
    return 0
}
# Also covers the temp Brewfile, which previously leaked on Ctrl-C.
trap cleanup EXIT INT TERM

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

# ----------------------------------------------------------------------------
# Trust the declared third-party taps
# ----------------------------------------------------------------------------
#
# Recent Homebrew refuses to load formulae or casks from non-official taps
# unless they are explicitly trusted, and `brew bundle` then dies on the very
# first one:
#
#   Error: Refusing to load formula withgraphite/tap/graphite from untrusted
#   tap withgraphite/tap.
#
# That kills the whole bundle — so no node, which then cascades into "npm not
# found" further down. Trusting is exactly what the feature is for: we are
# vouching for the taps this Brewfile deliberately declares.
#
# `brew trust` accepts a tap that has not been tapped yet, so this can run
# before `brew bundle` does the tapping. Older Homebrew has no `brew trust` and
# does not enforce this, hence the capability check.
if brew trust --help >/dev/null 2>&1; then
    log_info "Trusting third-party taps declared in the Brewfile..."
    while IFS= read -r tap_name; do
        [[ -z "$tap_name" ]] && continue
        if brew trust --tap "$tap_name" >/dev/null 2>&1; then
            log_success "Trusted tap: $tap_name"
        else
            log_warning "Could not trust tap: $tap_name (brew bundle may refuse it)"
        fi
    done < <(awk -F'"' '/^[[:space:]]*tap[[:space:]]+"/ { print $2 }' "$BREWFILE")
fi

# Only the casks need sudo; --skip-apps installs none, so don't ask.
if [[ "$SKIP_APPS" != true ]]; then
    start_sudo_keepalive || true
fi

log_info "Installing Homebrew packages from $(basename "$BREWFILE")..."
if ! brew bundle --file "$bundle_file" --no-upgrade; then
    log_error "Failed to install Homebrew packages from Brewfile"
    FAILURES+=("brew-bundle")
fi

# temp_brewfile removal is handled by the EXIT trap.

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
