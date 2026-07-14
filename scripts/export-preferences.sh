#!/bin/bash
# ============================================================================
# Export Preferences Script
# ============================================================================
#
# Captures system preferences into the repo for committing.
# This is the reverse of link-files.sh for copy-type mappings.
#
# Usage:
#   ./scripts/export-preferences.sh           # Export all preferences
#   ./scripts/export-preferences.sh --dry-run # Preview without changes
#   ./scripts/export-preferences.sh --check   # Report drift, write nothing
#
# Workflow:
#   1. Configure apps on your machine
#   2. Run this script to capture settings
#   3. git diff   (readable! see below)
#   4. git commit && git push
#   5. On other machine: git pull && ./scripts/link-files.sh
#
# ---------------------------------------------------------------------------
# Why this does not just `cp` the plist
# ---------------------------------------------------------------------------
#
#   1. `cp` reads the file behind cfprefsd's back. cfprefsd caches preferences
#      in memory and writes lazily, so the on-disk file can be stale — a plain
#      copy silently captures the wrong bytes. `defaults export` asks cfprefsd,
#      which is the only way to get the true current state.
#
#   2. Plists interleave real settings with churn: launch counters, window
#      frames, update timestamps, analytics identities. Committing those raw
#      makes every export report drift, which trains you to ignore the report.
#      config/preference-filters.yaml strips them.
#
#   3. Some plist values are semantically identical but byte-different — Thaw
#      serialises JSON blobs with unstable key order, so those keys could never
#      compare equal. The normalizer canonicalises embedded JSON.
#
#   4. Binary plists are unreviewable in git ("Binary files differ"). Output is
#      sorted XML, so `git diff` shows exactly which setting changed.
#
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"
MAPPINGS_FILE="$CONFIG_DIR/config/file-mappings.yaml"
FILTERS_FILE="$CONFIG_DIR/config/preference-filters.yaml"
NORMALIZER="$SCRIPT_DIR/lib/normalize-plist.py"

# System python3 (Xcode CLT) — deliberately not brew's, so this works before
# Homebrew is installed on a fresh machine.
PYTHON="/usr/bin/python3"

DRY_RUN=false
CHECK_ONLY=false
VERBOSE=false
EXPORTED=0
SKIPPED=0
UNCHANGED=0
DRIFTED=0

# ============================================================================
# LOGGING
# ============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
DIM='\033[2m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_export() { echo -e "${GREEN}[EXPORT]${NC} $1"; }
log_skip() { echo -e "${YELLOW}[SKIP]${NC} $1"; }
log_same() { echo -e "${DIM}[OK]${NC} $1"; }
log_dry() { echo -e "${CYAN}[DRY-RUN]${NC} $1"; }
log_drift() { echo -e "${YELLOW}[DRIFT]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

for arg in "$@"; do
    case $arg in
        -n|--dry-run) DRY_RUN=true ;;
        -c|--check) CHECK_ONLY=true ;;
        -v|--verbose) VERBOSE=true ;;
        -h|--help)
            cat << EOF
Usage: $(basename "$0") [--dry-run|--check] [--verbose]

Exports system preferences to the repo for committing.
Only exports files defined in the 'copies' section of file-mappings.yaml.

  -n, --dry-run   Show what would be exported, write nothing
  -c, --check     Report semantic drift and exit non-zero if any, write nothing
  -v, --verbose   List the churn keys stripped from each plist

Plists are exported via 'defaults export', filtered through
config/preference-filters.yaml, and written as sorted XML so 'git diff' is
readable and only reports real setting changes.
EOF
            exit 0
            ;;
    esac
done

TMPDIR_RUN="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_RUN"' EXIT

# ============================================================================
# HELPERS
# ============================================================================

expand_path() { echo "${1/#\~/$HOME}"; }

get_repo_path() {
    local source="$1"
    if [[ "$source" = /* ]]; then echo "$source"; else echo "$CONFIG_DIR/$source"; fi
}

# com.stonerl.Thaw.plist -> com.stonerl.Thaw
domain_from_filename() { basename "$1" .plist; }

# Normalize a plist into a comparable, committable form.
normalize_to() {
    local domain="$1" src="$2" dest="$3" extra="$4"
    "$PYTHON" "$NORMALIZER" \
        --filters "$FILTERS_FILE" \
        --domain "$domain" \
        --in "$src" \
        --out "$dest" \
        $extra
}

# ----------------------------------------------------------------------------
# Export a plist domain: defaults export -> normalize -> repo
# ----------------------------------------------------------------------------
export_plist() {
    local repo_path="$1" name="$2"
    local domain
    domain="$(domain_from_filename "$repo_path")"

    local raw="$TMPDIR_RUN/$domain.raw.plist"
    local norm="$TMPDIR_RUN/$domain.norm.plist"

    # Ask cfprefsd for the true current state. This also works for sandboxed
    # apps (Velja): the bare domain resolves into the app's container.
    if ! defaults export "$domain" "$raw" 2>/dev/null; then
        log_skip "$name (domain not present)"
        ((SKIPPED++)); return
    fi

    local extra=""
    [[ "$VERBOSE" == true ]] && extra="--report-dropped"
    if ! normalize_to "$domain" "$raw" "$norm" "$extra"; then
        log_error "$name (normalize failed)"
        ((SKIPPED++)); return
    fi

    if [[ -f "$repo_path" ]] && cmp -s "$norm" "$repo_path"; then
        log_same "$name (unchanged)"
        ((UNCHANGED++)); return
    fi

    if [[ "$CHECK_ONLY" == true ]]; then
        log_drift "$name"
        ((DRIFTED++)); return
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_dry "Would export: $name"
    else
        cp "$norm" "$repo_path"
        log_export "$name"
    fi
    ((EXPORTED++))
}

# ----------------------------------------------------------------------------
# Export a non-plist file (e.g. claude/plugins/*.json): plain copy
# ----------------------------------------------------------------------------
export_file() {
    local repo_path="$1" system_path="$2" name="$3"

    if [[ ! -f "$system_path" ]]; then
        log_skip "$name (not installed)"
        ((SKIPPED++)); return
    fi

    if [[ -f "$repo_path" ]] && cmp -s "$system_path" "$repo_path"; then
        log_same "$name (unchanged)"
        ((UNCHANGED++)); return
    fi

    if [[ "$CHECK_ONLY" == true ]]; then
        log_drift "$name"
        ((DRIFTED++)); return
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_dry "Would export: $name"
    else
        cp "$system_path" "$repo_path"
        log_export "$name"
    fi
    ((EXPORTED++))
}

export_entry() {
    local source_rel="$1" target_rel="$2" os_filter="$3"

    # Only export on macOS
    [[ -n "$os_filter" && "$os_filter" != "macos" ]] && return

    local repo_path system_path name
    repo_path=$(get_repo_path "$source_rel")
    system_path=$(expand_path "$target_rel")
    name=$(basename "$repo_path")

    if [[ "$repo_path" == *.plist ]]; then
        export_plist "$repo_path" "$name"
    else
        export_file "$repo_path" "$system_path" "$name"
    fi
}

# ============================================================================
# MAIN
# ============================================================================

echo ""
if [[ "$CHECK_ONLY" == true ]]; then
    log_info "Checking for preference drift..."
elif [[ "$DRY_RUN" == true ]]; then
    log_info "Dry run - previewing preference export..."
else
    log_info "Exporting system preferences to repo..."
fi
echo ""

[[ -f "$MAPPINGS_FILE" ]] || { log_error "Config not found: $MAPPINGS_FILE"; exit 1; }
[[ -f "$FILTERS_FILE" ]] || { log_error "Filters not found: $FILTERS_FILE"; exit 1; }
[[ -x "$PYTHON" ]] || { log_error "System python3 not found at $PYTHON (install Xcode CLI tools)"; exit 1; }

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
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    if [[ "$line" =~ ^(symlinks|hardlinks|copies):$ ]]; then
        process_entry
        if [[ "${BASH_REMATCH[1]}" == "copies" ]]; then in_copies=true; else in_copies=false; fi
        continue
    fi

    [[ "$in_copies" != true ]] && continue

    if [[ "$line" =~ ^[[:space:]]*-[[:space:]] ]]; then
        process_entry
        if [[ "$line" =~ source:[[:space:]]*(.+)$ ]]; then entry_source="${BASH_REMATCH[1]}"; fi
        continue
    fi

    if [[ "$line" =~ ^[[:space:]]+source:[[:space:]]*(.+)$ ]]; then
        entry_source="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^[[:space:]]+target:[[:space:]]*(.+)$ ]]; then
        entry_target="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^[[:space:]]+os:[[:space:]]*(.+)$ ]]; then
        entry_os="${BASH_REMATCH[1]}"
    fi
done < "$MAPPINGS_FILE"

process_entry

# ----------------------------------------------------------------------------
# Keyboard shortcuts
# ----------------------------------------------------------------------------
# NOT run automatically: export-keyboard-shortcuts.sh round-trips \Uxxxx escapes
# incorrectly and has already committed a corrupted binding once (see the audit
# notes and git history around f5086cb). Run it by hand once it is fixed.
echo ""
log_info "Keyboard shortcuts: skipped (export script has a known unicode bug)"
echo -e "${DIM}    See scripts/export-keyboard-shortcuts.sh — do not run until fixed${NC}"

# ----------------------------------------------------------------------------
# Summary
# ----------------------------------------------------------------------------
echo ""
if [[ "$CHECK_ONLY" == true ]]; then
    echo "Drifted: $DRIFTED | Unchanged: $UNCHANGED | Skipped: $SKIPPED"
    if [[ $DRIFTED -gt 0 ]]; then
        echo ""
        log_info "Real setting changes are uncommitted. Run: ./scripts/export-preferences.sh"
        exit 1
    fi
elif [[ "$DRY_RUN" == true ]]; then
    echo "Would export: $EXPORTED | Unchanged: $UNCHANGED | Skipped: $SKIPPED"
else
    echo "Exported: $EXPORTED | Unchanged: $UNCHANGED | Skipped: $SKIPPED"
    if [[ $EXPORTED -gt 0 ]]; then
        echo ""
        log_info "Next steps:"
        echo "  cd ~/.config"
        echo "  git diff                # readable — shows the actual settings that changed"
        echo "  git add -A && git commit -m 'Update preferences' && git push"
    fi
fi
echo ""
