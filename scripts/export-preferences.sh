#!/bin/bash
# ============================================================================
# Export Preferences Script
# ============================================================================
#
# Copies system preference files (plists) back to the repo for committing.
# This is the reverse of link-files.sh for copy-type mappings.
#
# Usage:
#   ./scripts/export-preferences.sh           # Export all preferences
#   ./scripts/export-preferences.sh --dry-run # Preview without changes
#
# Workflow:
#   1. Configure apps on your machine
#   2. Run this script to capture settings
#   3. git commit && git push
#   4. On other machine: git pull && ./scripts/link-files.sh
#
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"
MAPPINGS_FILE="$CONFIG_DIR/config/file-mappings.yaml"

DRY_RUN=false
EXPORTED=0
SKIPPED=0
UNCHANGED=0

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
log_export() { echo -e "${GREEN}[EXPORT]${NC} $1"; }
log_skip() { echo -e "${YELLOW}[SKIP]${NC} $1"; }
log_same() { echo -e "${DIM}[OK]${NC} $1"; }
log_dry() { echo -e "${CYAN}[DRY-RUN]${NC} $1"; }

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

for arg in "$@"; do
    case $arg in
        -n|--dry-run) DRY_RUN=true ;;
        -h|--help)
            echo "Usage: $(basename "$0") [--dry-run]"
            echo ""
            echo "Exports system preferences to repo for committing."
            echo "Only exports files defined in the 'copies' section of file-mappings.yaml."
            exit 0
            ;;
    esac
done

# ============================================================================
# HELPERS
# ============================================================================

expand_path() {
    echo "${1/#\~/$HOME}"
}

get_repo_path() {
    local source="$1"
    if [[ "$source" = /* ]]; then
        echo "$source"
    else
        echo "$CONFIG_DIR/$source"
    fi
}

export_entry() {
    local source_rel="$1"
    local target_rel="$2"
    local os_filter="$3"

    # Skip if OS doesn't match (only export on macOS)
    if [[ -n "$os_filter" && "$os_filter" != "macos" ]]; then
        return
    fi

    local local_path=$(get_repo_path "$source_rel")
    local system_path=$(expand_path "$target_rel")
    local name=$(basename "$local_path")

    # Check if system file exists
    if [[ ! -f "$system_path" ]]; then
        log_skip "$name (not installed)"
        ((SKIPPED++))
        return
    fi

    # Check if files are identical
    if [[ -f "$local_path" ]] && cmp -s "$system_path" "$local_path"; then
        log_same "$name (unchanged)"
        ((UNCHANGED++))
        return
    fi

    # Export the file
    if [[ "$DRY_RUN" == true ]]; then
        log_dry "Would export: $name"
    else
        cp "$system_path" "$local_path"
        log_export "$name"
    fi
    ((EXPORTED++))
}

# ============================================================================
# MAIN
# ============================================================================

echo ""
if [[ "$DRY_RUN" == true ]]; then
    log_info "Dry run - previewing preference export..."
else
    log_info "Exporting system preferences to repo..."
fi
echo ""

[[ -f "$MAPPINGS_FILE" ]] || { echo "Config not found: $MAPPINGS_FILE"; exit 1; }

# Parse YAML - only process entries under 'copies:' section
in_copies=false
entry_source=""
entry_target=""
entry_os=""

process_entry() {
    [[ -z "$entry_source" || -z "$entry_target" ]] && return
    export_entry "$entry_source" "$entry_target" "$entry_os"
    entry_source="" entry_target="" entry_os=""
}

while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    # Detect section headers
    if [[ "$line" =~ ^(symlinks|hardlinks|copies):$ ]]; then
        process_entry
        if [[ "${BASH_REMATCH[1]}" == "copies" ]]; then
            in_copies=true
        else
            in_copies=false
        fi
        continue
    fi

    # Only process copies section
    [[ "$in_copies" != true ]] && continue

    # Detect new entry
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]] ]]; then
        process_entry
        if [[ "$line" =~ source:[[:space:]]*(.+)$ ]]; then
            entry_source="${BASH_REMATCH[1]}"
        fi
        continue
    fi

    # Parse entry fields
    if [[ "$line" =~ ^[[:space:]]+source:[[:space:]]*(.+)$ ]]; then
        entry_source="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^[[:space:]]+target:[[:space:]]*(.+)$ ]]; then
        entry_target="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^[[:space:]]+os:[[:space:]]*(.+)$ ]]; then
        entry_os="${BASH_REMATCH[1]}"
    fi
done < "$MAPPINGS_FILE"

# Process final entry
process_entry

# Summary
echo ""
if [[ "$DRY_RUN" == true ]]; then
    echo "Would export: $EXPORTED | Unchanged: $UNCHANGED | Skipped: $SKIPPED"
else
    echo "Exported: $EXPORTED | Unchanged: $UNCHANGED | Skipped: $SKIPPED"
    if [[ $EXPORTED -gt 0 ]]; then
        echo ""
        log_info "Next steps:"
        echo "  cd ~/.config"
        echo "  git add -A && git commit -m 'Update preferences' && git push"
    fi
fi
echo ""
