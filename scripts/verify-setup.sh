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

        if grep -Eq '^(export[[:space:]]+)?HOME_ASSISTANT_URL=' "$env_file"; then
            log_pass "HOME_ASSISTANT_URL configured"
        else
            log_warn "HOME_ASSISTANT_URL missing"
        fi

        if grep -Eq '^(export[[:space:]]+)?HOME_ASSISTANT_TOKEN=' "$env_file"; then
            log_pass "HOME_ASSISTANT_TOKEN configured"
        else
            log_warn "HOME_ASSISTANT_TOKEN missing"
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
        local ok=$(echo "$output" | grep -c "\[OK\]" || echo 0)
        local issues=$(echo "$output" | grep -c "\[WARN\]\|\[ERROR\]" || echo 0)

        if [[ $issues -eq 0 ]]; then
            log_pass "All $ok file mappings OK"
        else
            log_warn "$issues of $((ok + issues)) mappings need attention"
            echo -e "${DIM}    Run: ./scripts/link-files.sh --verify${NC}"
        fi
    fi
}

verify_keyboard_shortcuts() {
    [[ "$CURRENT_OS" != "macos" ]] && return

    log_section "Keyboard Shortcuts"

    local yaml_file="$SCRIPT_DIR/../config/keyboard-shortcuts.yaml"
    if [[ ! -f "$yaml_file" ]]; then
        log_fail "keyboard-shortcuts.yaml missing"
        return
    fi

    # Count domains in YAML
    local yaml_domains
    yaml_domains=$(grep -c '^[a-zA-Z][a-zA-Z0-9._-]*:$' "$yaml_file" 2>/dev/null || echo 0)

    # Count non-empty domains on system
    local nonempty_system=0
    local in_domain=false
    local has_entries=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^Found ]]; then
            if [[ "$in_domain" == true && "$has_entries" == true ]]; then
                ((nonempty_system++))
            fi
            in_domain=true
            has_entries=false
        elif [[ "$in_domain" == true && "$line" =~ =[[:space:]]*\" ]]; then
            has_entries=true
        fi
    done < <(defaults find NSUserKeyEquivalents 2>/dev/null)
    # Process last domain
    if [[ "$in_domain" == true && "$has_entries" == true ]]; then
        ((nonempty_system++))
    fi

    if [[ "$yaml_domains" -eq "$nonempty_system" ]]; then
        log_pass "Keyboard shortcuts: $yaml_domains domains tracked"
    else
        log_warn "Keyboard shortcuts: $yaml_domains in YAML, $nonempty_system on system"
        echo -e "${DIM}    Run: ./scripts/export-keyboard-shortcuts.sh${NC}"
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
verify_keyboard_shortcuts

show_summary

[[ $FAIL -eq 0 ]]
