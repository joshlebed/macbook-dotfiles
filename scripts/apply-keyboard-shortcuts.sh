#!/bin/bash
# ============================================================================
# Apply Keyboard Shortcuts
# ============================================================================
#
# Reads config/keyboard-shortcuts.yaml and writes shortcuts via defaults write.
# The YAML is authoritative: existing shortcuts are deleted before writing.
#
# Usage:
#   ./scripts/apply-keyboard-shortcuts.sh           # Apply all shortcuts
#   ./scripts/apply-keyboard-shortcuts.sh --dry-run  # Preview changes
#
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"
SHORTCUTS_FILE="$CONFIG_DIR/config/keyboard-shortcuts.yaml"

DRY_RUN=false
DOMAINS=0
SHORTCUTS=0

# ============================================================================
# LOGGING
# ============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_apply() { echo -e "${GREEN}[APPLY]${NC} $1"; }
log_dry() { echo -e "${CYAN}[DRY-RUN]${NC} $1"; }
log_skip() { echo -e "${DIM}[SKIP]${NC} $1"; }

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

for arg in "$@"; do
    case $arg in
        -n|--dry-run) DRY_RUN=true ;;
        -h|--help)
            echo "Usage: $(basename "$0") [--dry-run]"
            echo ""
            echo "Applies keyboard shortcuts from config/keyboard-shortcuts.yaml"
            exit 0
            ;;
    esac
done

# ============================================================================
# MAIN
# ============================================================================

[[ -f "$SHORTCUTS_FILE" ]] || { echo "Config not found: $SHORTCUTS_FILE"; exit 1; }

echo ""
if [[ "$DRY_RUN" == true ]]; then
    log_info "Dry run - previewing keyboard shortcut application..."
else
    log_info "Applying keyboard shortcuts..."
fi
echo ""

current_domain=""
domain_entries=()

apply_domain() {
    [[ -z "$current_domain" || ${#domain_entries[@]} -eq 0 ]] && return

    # Determine the defaults domain argument
    local domain_arg="$current_domain"
    if [[ "$current_domain" == "NSGlobalDomain" ]]; then
        domain_arg="-g"
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_dry "Would delete + rewrite $current_domain (${#domain_entries[@]} shortcuts)"
        for entry in "${domain_entries[@]}"; do
            local name="${entry%%=*}"
            local shortcut="${entry#*=}"
            log_dry "  $name → $shortcut"
        done
    else
        # Delete existing shortcuts for this domain
        defaults delete "$domain_arg" NSUserKeyEquivalents 2>/dev/null || true

        # Write each shortcut
        for entry in "${domain_entries[@]}"; do
            local name="${entry%%=*}"
            local shortcut="${entry#*=}"
            defaults write "$domain_arg" NSUserKeyEquivalents -dict-add "$name" "$shortcut"
        done
        log_apply "$current_domain (${#domain_entries[@]} shortcuts)"
    fi

    ((DOMAINS++))
    SHORTCUTS=$((SHORTCUTS + ${#domain_entries[@]}))
    domain_entries=()
}

while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    # Domain header: line starting with non-space, ending with colon
    if [[ "$line" =~ ^([a-zA-Z][a-zA-Z0-9._-]*):$ ]]; then
        apply_domain
        current_domain="${BASH_REMATCH[1]}"
        continue
    fi

    # Shortcut entry: 2-space indent, "Name: value"
    if [[ "$line" =~ ^[[:space:]]+(.+):[[:space:]]+\"(.+)\"$ ]]; then
        name="${BASH_REMATCH[1]}"
        shortcut="${BASH_REMATCH[2]}"
        domain_entries+=("${name}=${shortcut}")
    fi
done < "$SHORTCUTS_FILE"

# Process final domain
apply_domain

# Summary
echo ""
if [[ "$DRY_RUN" == true ]]; then
    echo "Would apply: $SHORTCUTS shortcuts across $DOMAINS domains"
else
    echo "Applied: $SHORTCUTS shortcuts across $DOMAINS domains"
    echo ""
    log_info "Restart affected apps for shortcuts to take effect."
fi
echo ""
