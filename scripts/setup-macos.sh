#!/bin/bash
# ============================================================================
# macOS Development Environment Setup Script
# ============================================================================
#
# Description:
#   Unified setup script for macOS development environments.
#   Installs and configures: Homebrew, CLI tools, GUI apps, zsh, oh-my-zsh,
#   and all dotfile symlinks/hardlinks.
#
# Usage:
#   ./scripts/setup-macos.sh           # Full setup
#   ./scripts/setup-macos.sh --help    # Show help
#   ./scripts/setup-macos.sh --dry-run # Preview what would be done
#   ./scripts/setup-macos.sh --skip-brew # Skip Homebrew installation
#
# Repository: https://github.com/joshlebed/macbook-dotfiles
# ============================================================================

set -e  # Exit on error

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"

# Options
DRY_RUN=false
SKIP_BREW=false
SKIP_APPS=false

# ============================================================================
# LOGGING AND OUTPUT FUNCTIONS
# ============================================================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}  $1${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

log_step() {
    echo -e "${CYAN}→${NC} $1"
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

show_help() {
    cat << EOF
macOS Development Environment Setup

Usage: $(basename "$0") [OPTIONS]

Options:
    -h, --help       Show this help message
    -n, --dry-run    Preview what would be done without making changes
    --skip-brew      Skip Homebrew and package installation
    --skip-apps      Skip GUI application installation (install CLI tools only)

Examples:
    $(basename "$0")              # Full setup
    $(basename "$0") --dry-run    # Preview changes
    $(basename "$0") --skip-brew  # Skip brew, just do symlinks

EOF
    exit 0
}

run_script() {
    local script="$1"
    local description="$2"

    if [[ ! -f "$script" ]]; then
        log_error "Script not found: $script"
        return 1
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_step "[DRY-RUN] Would run: $description"
        return 0
    fi

    log_step "Running: $description"
    if bash "$script"; then
        return 0
    else
        log_error "Script failed: $script"
        return 1
    fi
}

run_script_with_args() {
    local script="$1"
    local args="$2"
    local description="$3"

    if [[ ! -f "$script" ]]; then
        log_error "Script not found: $script"
        return 1
    fi

    log_step "Running: $description"
    if bash "$script" $args; then
        return 0
    else
        log_error "Script failed: $script"
        return 1
    fi
}

check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        log_error "This script is for macOS only. For Linux, use setup-linux-dev.sh"
        exit 1
    fi
}

check_xcode_cli() {
    if ! xcode-select -p &>/dev/null; then
        log_info "Installing Xcode Command Line Tools..."
        if [[ "$DRY_RUN" == true ]]; then
            log_step "[DRY-RUN] Would install Xcode CLI tools"
        else
            xcode-select --install 2>/dev/null || true
            log_warning "Please complete the Xcode CLI tools installation and re-run this script"
            exit 1
        fi
    else
        log_info "Xcode CLI tools already installed"
    fi
}

# ============================================================================
# PARSE ARGUMENTS
# ============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            --skip-brew)
                SKIP_BREW=true
                shift
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
}

# ============================================================================
# SETUP STEPS
# ============================================================================

step_homebrew() {
    log_section "Step 1: Homebrew & Packages"

    if [[ "$SKIP_BREW" == true ]]; then
        log_warning "Skipping Homebrew installation (--skip-brew)"
        return 0
    fi

    if [[ "$SKIP_APPS" == true ]]; then
        log_info "Installing CLI tools only (--skip-apps)"
        # TODO: Add a flag to brew_install_all.sh for CLI-only mode
    fi

    run_script "$SCRIPT_DIR/brew_install_all.sh" "Homebrew and packages"
}

step_shell() {
    log_section "Step 2: Shell Setup (zsh + oh-my-zsh)"

    run_script "$SCRIPT_DIR/install_zsh_and_omz.sh" "zsh and oh-my-zsh installation"
}

step_file_mappings() {
    log_section "Step 3: File Mappings"

    if [[ "$DRY_RUN" == true ]]; then
        run_script_with_args "$SCRIPT_DIR/link-files.sh" "--dry-run" "file mappings (dry run)"
    else
        run_script "$SCRIPT_DIR/link-files.sh" "file mappings"
    fi
}

show_manual_steps() {
    log_section "Manual Configuration Required"

    echo "The following apps require manual configuration:"
    echo ""
    echo "  📋 Keyboard Maestro"
    echo "     File → Start Syncing Macros → select km_macros.kmsync"
    echo ""
    echo "  🖥️  iTerm2"
    echo "     Preferences → General → Preferences → Load from ~/.config/iterm2"
    echo ""
    echo "  🪟 Slate (if using)"
    echo "     Download from: https://github.com/jigish/slate"
    echo ""
    echo "  ☁️  Google Drive"
    echo "     Sign in and configure sync folders"
    echo ""
    echo "  ✅ TickTick"
    echo "     Sign in to sync tasks"
    echo ""
}

show_summary() {
    log_section "Setup Complete!"

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}This was a dry run. No changes were made.${NC}"
        echo "Run without --dry-run to apply changes."
        echo ""
        return
    fi

    echo "Your macOS development environment is ready!"
    echo ""
    echo "What was configured:"
    echo "  ✓ Homebrew and packages"
    echo "  ✓ Zsh with Oh My Zsh"
    echo "  ✓ All file mappings (symlinks, hardlinks, copies)"
    echo ""
    echo "Next steps:"
    echo "  1. Open a new terminal or run: exec zsh"
    echo "  2. Complete the manual configuration steps above"
    echo ""
    echo "Repository: https://github.com/joshlebed/macbook-dotfiles"
    echo ""
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    parse_args "$@"

    echo ""
    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║       macOS Development Environment Setup              ║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        log_warning "DRY RUN MODE - No changes will be made"
        echo ""
    fi

    # Verify we're on macOS
    check_macos

    # Verify we're in the right directory
    if [[ ! -d "$CONFIG_DIR/.git" ]]; then
        log_error "This script must be run from the dotfiles repository"
        log_error "Expected location: ~/.config/scripts/setup-macos.sh"
        exit 1
    fi

    log_info "Config directory: $CONFIG_DIR"
    echo ""

    # Check for Xcode CLI tools (required for git, brew, etc.)
    check_xcode_cli

    # Run setup steps
    step_homebrew
    step_shell
    step_file_mappings

    # Show manual steps and summary
    show_manual_steps
    show_summary

    # Run verification
    log_section "Verification"
    if [[ "$DRY_RUN" != true ]]; then
        log_step "Running verification..."
        "$SCRIPT_DIR/verify-setup.sh" --quick || true
    else
        log_step "[DRY-RUN] Would run verification"
    fi
}

# Trap to handle errors
trap 'log_error "Setup failed! Check the errors above."' ERR

# Run main
main "$@"
