#!/bin/bash
# ============================================================================
# Unified File Linking Script
# ============================================================================
#
# Reads file-mappings.yaml and creates symlinks, hardlinks, and copies.
# Works on both macOS and Linux.
#
# Usage:
#   ./scripts/link-files.sh              # Apply all mappings
#   ./scripts/link-files.sh --dry-run    # Preview without changes
#   ./scripts/link-files.sh --verify     # Check current status
#
# ============================================================================

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"
MAPPINGS_FILE="$CONFIG_DIR/config/file-mappings.yaml"

# Detect OS
if [[ "$(uname)" == "Darwin" ]]; then
    CURRENT_OS="macos"
else
    CURRENT_OS="linux"
fi

# Options
DRY_RUN=false
VERIFY_ONLY=false
FILTER_TYPE=""

# Counters
TOTAL_OK=0
TOTAL_CREATED=0
TOTAL_SKIPPED=0
TOTAL_FAILED=0

# ============================================================================
# LOGGING
# ============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
DIM='\033[2m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_skip() { echo -e "${DIM}[SKIP]${NC} $1"; }
log_create() { echo -e "${GREEN}[CREATE]${NC} $1"; }
log_dry() { echo -e "${CYAN}[DRY-RUN]${NC} $1"; }

log_section() {
    echo ""
    echo -e "${MAGENTA}── $1 ──${NC}"
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

show_help() {
    cat << EOF
Unified File Linking Script

Usage: $(basename "$0") [OPTIONS]

Options:
    -h, --help       Show this help message
    -n, --dry-run    Preview changes without applying them
    -v, --verify     Check status of all mappings (no changes)
    -t, --type TYPE  Only process mappings of TYPE (symlink|hardlink|copy)

Detected OS: $CURRENT_OS

EOF
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help) show_help ;;
            -n|--dry-run) DRY_RUN=true; shift ;;
            -v|--verify) VERIFY_ONLY=true; shift ;;
            -t|--type) FILTER_TYPE="$2"; shift 2 ;;
            *) log_error "Unknown option: $1"; exit 1 ;;
        esac
    done
}

# ============================================================================
# PATH HELPERS
# ============================================================================

expand_path() {
    echo "${1/#\~/$HOME}"
}

get_source_path() {
    local source="$1"
    if [[ "$source" = /* ]]; then
        echo "$source"
    else
        echo "$CONFIG_DIR/$source"
    fi
}

# ============================================================================
# STATUS CHECKING
# ============================================================================

symlink_is_correct() {
    local target="$1"
    local source="$2"
    [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]
}

hardlink_is_correct() {
    local source="$1"
    local target="$2"
    [[ -f "$source" ]] && [[ -f "$target" ]] || return 1

    local inode1 inode2
    if [[ "$CURRENT_OS" == "macos" ]]; then
        inode1=$(stat -f %i "$source" 2>/dev/null)
        inode2=$(stat -f %i "$target" 2>/dev/null)
    else
        inode1=$(stat -c %i "$source" 2>/dev/null)
        inode2=$(stat -c %i "$target" 2>/dev/null)
    fi
    [[ "$inode1" == "$inode2" ]]
}

files_identical() {
    [[ -f "$1" ]] && [[ -f "$2" ]] && cmp -s "$1" "$2"
}

# ============================================================================
# LINKING FUNCTIONS
# ============================================================================

ensure_parent_dir() {
    local target="$1"
    local dir=$(dirname "$target")
    [[ -d "$dir" ]] || mkdir -p "$dir"
}

backup_existing() {
    local target="$1"
    if [[ -e "$target" ]] && [[ ! -L "$target" ]]; then
        mv "$target" "${target}.old"
        return 0
    elif [[ -L "$target" ]]; then
        rm "$target"
        return 0
    fi
    return 1
}

create_symlink() {
    local source="$1" target="$2"
    local name=$(basename "$target")

    [[ -e "$source" ]] || { log_warning "Source missing: $source"; ((TOTAL_FAILED++)); return 1; }

    if symlink_is_correct "$target" "$source"; then
        [[ "$VERIFY_ONLY" == true ]] && log_success "symlink: $name" || log_skip "Already linked: $name"
        ((TOTAL_OK++)); return 0
    fi

    if [[ "$VERIFY_ONLY" == true ]]; then
        [[ -e "$target" ]] && log_warning "symlink: $name (wrong target)" || log_error "symlink: $name (missing)"
        ((TOTAL_FAILED++)); return 1
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_dry "Would symlink: $name"; ((TOTAL_CREATED++)); return 0
    fi

    ensure_parent_dir "$target"
    backup_existing "$target"
    ln -s "$source" "$target"
    [[ "$CURRENT_OS" == "macos" ]] && chflags nouchg "$target" 2>/dev/null || true
    log_create "Symlinked: $name"; ((TOTAL_CREATED++))
}

create_hardlink() {
    local source="$1" target="$2"
    local name=$(basename "$target")

    [[ -f "$source" ]] || { log_warning "Source missing: $source"; ((TOTAL_FAILED++)); return 1; }

    if hardlink_is_correct "$source" "$target"; then
        [[ "$VERIFY_ONLY" == true ]] && log_success "hardlink: $name" || log_skip "Already hardlinked: $name"
        ((TOTAL_OK++)); return 0
    fi

    if [[ "$VERIFY_ONLY" == true ]]; then
        [[ -e "$target" ]] && log_warning "hardlink: $name (wrong)" || log_error "hardlink: $name (missing)"
        ((TOTAL_FAILED++)); return 1
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_dry "Would hardlink: $name"; ((TOTAL_CREATED++)); return 0
    fi

    ensure_parent_dir "$target"
    [[ -e "$target" ]] && mv "$target" "${target}.old"
    ln "$source" "$target"
    log_create "Hardlinked: $name"; ((TOTAL_CREATED++))
}

copy_file() {
    local source="$1" target="$2"
    local name=$(basename "$target")

    [[ -f "$source" ]] || { log_warning "Source missing: $source"; ((TOTAL_FAILED++)); return 1; }

    if files_identical "$source" "$target"; then
        [[ "$VERIFY_ONLY" == true ]] && log_success "copy: $name" || log_skip "Already up to date: $name"
        ((TOTAL_OK++)); return 0
    fi

    if [[ "$VERIFY_ONLY" == true ]]; then
        [[ -e "$target" ]] && log_warning "copy: $name (differs)" || log_error "copy: $name (missing)"
        ((TOTAL_FAILED++)); return 1
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_dry "Would copy: $name"; ((TOTAL_CREATED++)); return 0
    fi

    ensure_parent_dir "$target"
    [[ -f "$target" ]] && mv "$target" "${target}.old"
    cp "$source" "$target"
    log_create "Copied: $name"; ((TOTAL_CREATED++))
}

# ============================================================================
# YAML PARSING
# ============================================================================

process_mappings() {
    [[ -f "$MAPPINGS_FILE" ]] || { log_error "Config not found: $MAPPINGS_FILE"; exit 1; }

    local current_type=""
    local entry_source=""
    local entry_target=""
    local entry_os=""
    local in_entry=false

    process_entry() {
        [[ -z "$entry_source" || -z "$entry_target" ]] && return

        # Skip if OS doesn't match
        if [[ -n "$entry_os" && "$entry_os" != "$CURRENT_OS" ]]; then
            ((TOTAL_SKIPPED++))
            entry_source="" entry_target="" entry_os=""
            return
        fi

        # Skip if filtering by type
        if [[ -n "$FILTER_TYPE" && "$current_type" != "$FILTER_TYPE" ]]; then
            entry_source="" entry_target="" entry_os=""
            return
        fi

        local source=$(get_source_path "$entry_source")
        local target=$(expand_path "$entry_target")

        case "$current_type" in
            symlink)  create_symlink "$source" "$target" ;;
            hardlink) create_hardlink "$source" "$target" ;;
            copy)     copy_file "$source" "$target" ;;
        esac

        entry_source="" entry_target="" entry_os=""
    }

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        # Detect section headers (symlinks:, hardlinks:, copies:)
        if [[ "$line" =~ ^(symlinks|hardlinks|copies):$ ]]; then
            # Process any pending entry before switching sections
            process_entry
            local section="${BASH_REMATCH[1]}"
            case "$section" in
                symlinks)  current_type="symlink"; log_section "Symlinks" ;;
                hardlinks) current_type="hardlink"; log_section "Hardlinks" ;;
                copies)    current_type="copy"; log_section "Copies" ;;
            esac
            continue
        fi

        # Detect new entry (starts with "  - ")
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]] ]]; then
            # Process previous entry
            process_entry
            in_entry=true
            # Check if source is on same line: "  - source: value"
            if [[ "$line" =~ source:[[:space:]]*(.+)$ ]]; then
                entry_source="${BASH_REMATCH[1]}"
            fi
            continue
        fi

        # Parse entry fields
        if [[ "$in_entry" == true ]]; then
            if [[ "$line" =~ ^[[:space:]]+source:[[:space:]]*(.+)$ ]]; then
                entry_source="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^[[:space:]]+target:[[:space:]]*(.+)$ ]]; then
                entry_target="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^[[:space:]]+os:[[:space:]]*(.+)$ ]]; then
                entry_os="${BASH_REMATCH[1]}"
            fi
            # reason field is ignored (documentation only)
        fi
    done < "$MAPPINGS_FILE"

    # Process final entry
    process_entry
}

show_summary() {
    echo ""
    echo -e "${MAGENTA}── Summary ($CURRENT_OS) ──${NC}"

    if [[ "$VERIFY_ONLY" == true ]]; then
        echo "  OK: $TOTAL_OK | Issues: $TOTAL_FAILED | Skipped (other OS): $TOTAL_SKIPPED"
        [[ $TOTAL_FAILED -eq 0 ]] && log_success "All mappings verified!" || log_warning "$TOTAL_FAILED mappings need attention"
    elif [[ "$DRY_RUN" == true ]]; then
        echo "  Would create: $TOTAL_CREATED | Already OK: $TOTAL_OK | Skipped: $TOTAL_SKIPPED"
    else
        echo "  Created: $TOTAL_CREATED | Already OK: $TOTAL_OK | Failed: $TOTAL_FAILED"
    fi
    echo ""
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    parse_args "$@"

    echo ""
    if [[ "$VERIFY_ONLY" == true ]]; then
        log_info "Verifying file mappings ($CURRENT_OS)..."
    elif [[ "$DRY_RUN" == true ]]; then
        log_info "Dry run - previewing file mappings ($CURRENT_OS)..."
    else
        log_info "Processing file mappings ($CURRENT_OS)..."
    fi

    process_mappings
    show_summary
}

main "$@"
