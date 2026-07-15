#!/bin/bash
# ============================================================================
# Verify Setup Script
# ============================================================================
#
# Checks the current state of the development environment.
# Works on both macOS and Linux.
#
# Usage:
#   ./scripts/verify-setup.sh           # Full verification
#   ./scripts/verify-setup.sh --quick   # Skip slow checks
#
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect OS
if [[ "$(uname)" == "Darwin" ]]; then
    CURRENT_OS="macos"
else
    CURRENT_OS="linux"
fi

QUICK_MODE=false
PASS=0
WARN=0
FAIL=0

# ============================================================================
# LOGGING
# ============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
DIM='\033[2m'
NC='\033[0m'

log_pass() { echo -e "${GREEN}  ✓${NC} $1"; ((PASS++)); return 0; }
log_warn() { echo -e "${YELLOW}  ⚠${NC} $1"; ((WARN++)); return 0; }
log_fail() { echo -e "${RED}  ✗${NC} $1"; ((FAIL++)); return 0; }
log_info() { echo -e "${DIM}  ○${NC} $1"; return 0; }
log_section() { echo -e "\n${MAGENTA}$1${NC}"; }

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

for arg in "$@"; do
    case $arg in
        -q|--quick) QUICK_MODE=true ;;
        -h|--help) echo "Usage: $(basename "$0") [--quick]"; exit 0 ;;
    esac
done

# ============================================================================
# CHECK FUNCTIONS
# ============================================================================

check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        log_pass "${2:-$1} installed"
        return 0
    else
        log_fail "${2:-$1} not installed"
        return 1
    fi
}

check_dir() {
    if [[ -d "$1" ]]; then
        log_pass "$2 exists"
        return 0
    else
        log_fail "$2 missing"
        return 1
    fi
}

# ============================================================================
# VERIFICATION
# ============================================================================

verify_prerequisites() {
    log_section "Prerequisites"

    if [[ "$CURRENT_OS" == "macos" ]]; then
        if command -v xcode-select >/dev/null 2>&1 && xcode-select -p &>/dev/null; then
            log_pass "Xcode CLI tools"
        else
            log_warn "Xcode CLI tools"
        fi

        # With full Xcode installed (the Brewfile pulls it via mas), every
        # xcodebuild/xcrun call is gated on the licence — including `swift
        # build`, which the InstantSpaceSwitcher fork needs. Silent trap
        # otherwise: things just refuse to compile.
        if [[ -d /Applications/Xcode.app ]]; then
            local lic
            lic=$(/usr/bin/xcodebuild -license check 2>&1)
            if [[ $? -eq 0 ]]; then
                log_pass "Xcode license accepted"
            elif grep -qi "requires Xcode" <<< "$lic"; then
                log_info "Xcode installed but CLT selected (no license gate)"
            else
                log_fail "Xcode license NOT accepted — blocks swift build/cocoapods/fastlane"
                echo -e "${DIM}    Run: sudo xcodebuild -license accept${NC}"
            fi
        fi

        check_command brew "Homebrew"
    else
        check_command apt "Package manager (apt)" || check_command dnf "Package manager (dnf)" || check_command pacman "Package manager (pacman)" || true
    fi
    check_command git "Git"
    check_command curl "curl"
}

verify_shell() {
    log_section "Shell"

    check_command zsh "Zsh"
    [[ -d "$HOME/.oh-my-zsh" ]] && log_pass "Oh My Zsh" || log_fail "Oh My Zsh"

    if [[ -L "$HOME/.zshrc" ]]; then
        [[ "$(readlink "$HOME/.zshrc")" == *".config/.zshrc"* ]] && log_pass ".zshrc symlinked" || log_warn ".zshrc symlinked elsewhere"
    else
        [[ -f "$HOME/.zshrc" ]] && log_warn ".zshrc exists but not symlinked" || log_fail ".zshrc missing"
    fi
}

verify_tools() {
    log_section "Tools"

    check_command node "Node.js"
    check_command npm "npm"
    check_command fzf "fzf"
    check_command tmux "tmux"
    check_command gh "GitHub CLI"

    # Optional tools
    if command -v claude >/dev/null 2>&1 || [[ -f "$HOME/.claude/bin/claude" ]]; then
        log_pass "Claude Code"
    else
        log_info "Claude Code (optional)"
    fi
}

verify_local_environment() {
    log_section "Local Environment"

    local env_file="$HOME/.environment-specifics.zshrc"
    local example_file="$SCRIPT_DIR/../.environment-specifics.example.zshrc"

    if [[ -f "$env_file" ]]; then
        log_pass "~/.environment-specifics.zshrc exists"

        local mode
        if [[ "$CURRENT_OS" == "macos" ]]; then
            mode=$(stat -f %Lp "$env_file" 2>/dev/null)
        else
            mode=$(stat -c %a "$env_file" 2>/dev/null)
        fi

        if [[ -n "$mode" && "$mode" -le 600 ]]; then
            log_pass "~/.environment-specifics.zshrc permissions"
        else
            log_warn "~/.environment-specifics.zshrc should be chmod 600"
        fi

        # Derive the expected variables from the tracked template rather than
        # hardcoding them here — that hardcoded list drifted to covering 2 of 8.
        if [[ -f "$example_file" ]]; then
            local missing=0 expected=0 var
            while IFS= read -r var; do
                [[ -z "$var" ]] && continue
                ((expected++))
                if ! grep -Eq "^(export[[:space:]]+)?${var}=" "$env_file"; then
                    log_warn "$var missing from ~/.environment-specifics.zshrc"
                    ((missing++))
                fi
            done < <(grep -oE '^(export[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*=' "$example_file" \
                        | sed -E 's/^export[[:space:]]+//; s/=$//' | sort -u)
            if [[ $missing -eq 0 && $expected -gt 0 ]]; then
                log_pass "all $expected template variables present"
            fi
        fi
    else
        log_warn "~/.environment-specifics.zshrc missing"
        if [[ -f "$example_file" ]]; then
            echo -e "${DIM}    Start with: cp ~/.config/.environment-specifics.example.zshrc ~/.environment-specifics.zshrc${NC}"
        fi
    fi
}

verify_homebrew_bundle() {
    [[ "$CURRENT_OS" != "macos" ]] && return

    log_section "Homebrew Bundle"

    local audit_script="$SCRIPT_DIR/audit-brew.sh"
    local brewfile="$SCRIPT_DIR/../Brewfile"

    if [[ ! -f "$brewfile" ]]; then
        log_warn "Brewfile missing"
        return
    fi

    if [[ ! -x "$audit_script" ]]; then
        log_warn "audit-brew.sh missing or not executable"
        return
    fi

    if "$audit_script" >/dev/null 2>&1; then
        log_pass "Installed Homebrew packages match Brewfile"
    else
        log_warn "Homebrew packages differ from Brewfile"
        echo -e "${DIM}    Run: ./scripts/audit-brew.sh${NC}"
    fi
}

verify_apps() {
    [[ "$CURRENT_OS" != "macos" ]] && return

    log_section "Apps (macOS)"

    local apps=(
        "/Applications/iTerm.app:iTerm2"
        "/Applications/Visual Studio Code.app:VS Code"
        "/Applications/Cursor.app:Cursor"
        "/Applications/Raycast.app:Raycast"
    )

    for app in "${apps[@]}"; do
        IFS=':' read -r path name <<< "$app"
        [[ -d "$path" ]] && log_pass "$name" || log_warn "$name"
    done
}

verify_file_mappings() {
    log_section "File Mappings"

    if [[ -f "$SCRIPT_DIR/link-files.sh" ]]; then
        local output
        output=$("$SCRIPT_DIR/link-files.sh" --verify 2>&1)
        # Count only per-mapping lines. link-files.sh ends with its own summary
        # ("[OK] All mappings verified!" / "[WARN] N mappings need attention"),
        # which matches these patterns too and would be counted as an extra
        # mapping — inflating the totals and reporting 2 issues when there is 1.
        #
        # grep -c already prints 0 when nothing matches; it just exits 1. A
        # `|| echo 0` would append a second line and make this "0\n0".
        local ok issues
        # `.*` between the tag and the label because link-files.sh emits ANSI
        # colour resets there ("<esc>[0;32m[OK]<esc>[0m symlink: .zshrc").
        ok=$(echo "$output" | grep -cE "\[OK\].*(symlink|copy|plist):" || true)
        issues=$(echo "$output" | grep -cE "\[(WARN|ERROR)\].*(symlink|copy|plist):" || true)

        if [[ $issues -eq 0 ]]; then
            log_pass "All $ok file mappings OK"
        else
            log_warn "$issues of $((ok + issues)) mappings need attention"
            echo -e "${DIM}    Run: ./scripts/link-files.sh --verify${NC}"
        fi
    fi
}

verify_editor_extensions() {
    [[ "$CURRENT_OS" != "macos" ]] && return

    log_section "Editor Extensions"

    local script="$SCRIPT_DIR/editor-extensions.sh"
    if [[ ! -x "$script" ]]; then
        log_warn "editor-extensions.sh missing"
        return
    fi

    if "$script" --check >/dev/null 2>&1; then
        log_pass "VS Code + Cursor extensions in sync"
    else
        log_warn "Editor extensions differ from tracked lists"
        echo -e "${DIM}    Run: ./scripts/editor-extensions.sh --check${NC}"
    fi
}

verify_macos_defaults() {
    [[ "$CURRENT_OS" != "macos" ]] && return

    log_section "macOS Defaults"

    local script="$SCRIPT_DIR/apply-macos-defaults.sh"
    if [[ ! -x "$script" ]]; then
        log_warn "apply-macos-defaults.sh missing"
        return
    fi

    if "$script" --check >/dev/null 2>&1; then
        log_pass "macOS defaults match"
    else
        log_warn "Some macOS defaults differ"
        echo -e "${DIM}    Run: ./scripts/apply-macos-defaults.sh --check${NC}"
    fi
}

verify_login_items() {
    [[ "$CURRENT_OS" != "macos" ]] && return

    log_section "Login Items"

    local script="$SCRIPT_DIR/login-items.sh"
    if [[ ! -x "$script" ]]; then
        log_warn "login-items.sh missing"
        return
    fi

    if "$script" --check >/dev/null 2>&1; then
        log_pass "Login items in sync"
    else
        log_warn "Login items differ from config/login-items.yaml"
        echo -e "${DIM}    Run: ./scripts/login-items.sh --check${NC}"
    fi
}

# ============================================================================
# SUMMARY
# ============================================================================

show_summary() {
    echo ""
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if [[ $FAIL -eq 0 && $WARN -eq 0 ]]; then
        echo -e "${GREEN}  All $PASS checks passed!${NC}"
    elif [[ $FAIL -eq 0 ]]; then
        echo -e "${YELLOW}  $PASS passed, $WARN warnings${NC}"
    else
        echo -e "${RED}  $PASS passed, $WARN warnings, $FAIL failed${NC}"
    fi

    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ============================================================================
# MAIN
# ============================================================================

echo ""
echo -e "${MAGENTA}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║  Setup Verification ($CURRENT_OS)                        ${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════╝${NC}"

verify_prerequisites
verify_shell
verify_tools
verify_local_environment
verify_homebrew_bundle
verify_apps
verify_file_mappings
verify_editor_extensions
verify_macos_defaults
verify_login_items

show_summary

[[ $FAIL -eq 0 ]]
