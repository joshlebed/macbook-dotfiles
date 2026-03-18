#!/usr/bin/env bash
# ============================================================================
# Export Keyboard Shortcuts
# ============================================================================
# Requires bash 4+ for associative arrays (macOS: brew install bash)
#
# Discovers all NSUserKeyEquivalents on the system and writes them to
# config/keyboard-shortcuts.yaml. This is the reverse of apply-keyboard-shortcuts.sh.
#
# Usage:
#   ./scripts/export-keyboard-shortcuts.sh           # Export to YAML
#   ./scripts/export-keyboard-shortcuts.sh --dry-run  # Print to stdout
#
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"
SHORTCUTS_FILE="$CONFIG_DIR/config/keyboard-shortcuts.yaml"

DRY_RUN=false

# ============================================================================
# LOGGING
# ============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_export() { echo -e "${GREEN}[EXPORT]${NC} $1"; }
log_dry() { echo -e "${CYAN}[DRY-RUN]${NC} $1"; }
log_same() { echo -e "${DIM}[OK]${NC} $1"; }

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

for arg in "$@"; do
    case $arg in
        -n|--dry-run) DRY_RUN=true ;;
        -h|--help)
            echo "Usage: $(basename "$0") [--dry-run]"
            echo ""
            echo "Exports keyboard shortcuts from system to config/keyboard-shortcuts.yaml"
            exit 0
            ;;
    esac
done

# ============================================================================
# DISCOVER SHORTCUTS
# ============================================================================

# Associative arrays: domain -> list of "name=shortcut" entries
declare -A domain_entries
declare -a domain_order=()

current_domain=""
in_dict=false

while IFS= read -r line; do
    # New domain block
    if [[ "$line" =~ Found.*domain\ \'(.+)\': ]]; then
        current_domain="${BASH_REMATCH[1]}"
        # Map Apple Global Domain to NSGlobalDomain
        if [[ "$current_domain" == "Apple Global Domain" ]]; then
            current_domain="NSGlobalDomain"
        fi
        in_dict=false
        continue
    fi

    # Start of NSUserKeyEquivalents dict
    if [[ "$line" =~ NSUserKeyEquivalents.*\{ ]]; then
        in_dict=true
        continue
    fi

    # End of dict
    if [[ "$in_dict" == true && "$line" =~ ^[[:space:]]*\} ]]; then
        in_dict=false
        continue
    fi

    # Shortcut entry inside dict
    # Handles both quoted and unquoted keys: "Menu Item" = "shortcut"; or Key = "shortcut";
    if [[ "$in_dict" == true && "$line" =~ ^[[:space:]]+\"?([^\"=]+)\"?[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then
        name="${BASH_REMATCH[1]}"
        shortcut="${BASH_REMATCH[2]}"
        # Trim trailing whitespace from name
        name="${name%"${name##*[![:space:]]}"}"

        if [[ -z "${domain_entries[$current_domain]+_}" ]]; then
            domain_order+=("$current_domain")
            domain_entries[$current_domain]=""
        fi

        if [[ -n "${domain_entries[$current_domain]}" ]]; then
            domain_entries[$current_domain]+=$'\n'
        fi
        domain_entries[$current_domain]+="${name}=${shortcut}"
    fi
done < <(defaults find NSUserKeyEquivalents 2>/dev/null)

# ============================================================================
# GENERATE YAML
# ============================================================================

generate_yaml() {
    echo "# Keyboard Shortcuts (NSUserKeyEquivalents)"
    echo "#"
    echo "# Managed by:"
    echo "#   Apply:  scripts/apply-keyboard-shortcuts.sh"
    echo "#   Export: scripts/export-keyboard-shortcuts.sh"
    echo "#"
    echo "# Key notation: @ = Cmd, ~ = Option, ^ = Control, $ = Shift"

    # Sort domains: NSGlobalDomain first, then alphabetical
    local sorted_domains=()
    local has_global=false

    for domain in "${domain_order[@]}"; do
        if [[ "$domain" == "NSGlobalDomain" ]]; then
            has_global=true
        else
            sorted_domains+=("$domain")
        fi
    done

    # Sort the non-global domains (guard against empty array)
    if [[ ${#sorted_domains[@]} -gt 0 ]]; then
        IFS=$'\n' sorted_domains=($(sort <<<"${sorted_domains[*]}")); unset IFS
    fi

    # NSGlobalDomain first
    if [[ "$has_global" == true ]]; then
        sorted_domains=("NSGlobalDomain" "${sorted_domains[@]}")
    fi

    for domain in "${sorted_domains[@]}"; do
        echo ""
        echo "${domain}:"
        while IFS= read -r entry; do
            name="${entry%%=*}"
            shortcut="${entry#*=}"
            echo "  ${name}: \"${shortcut}\""
        done <<< "${domain_entries[$domain]}"
    done
}

# ============================================================================
# OUTPUT
# ============================================================================

echo ""
if [[ "$DRY_RUN" == true ]]; then
    log_info "Dry run - would write to $SHORTCUTS_FILE:"
    echo ""
    generate_yaml
else
    yaml_content="$(generate_yaml)"

    # Check if file changed (use $yaml_content, not a second generate_yaml call)
    if [[ -f "$SHORTCUTS_FILE" ]] && [[ "$yaml_content" == "$(cat "$SHORTCUTS_FILE")" ]]; then
        log_same "keyboard-shortcuts.yaml (unchanged)"
    else
        echo "$yaml_content" > "$SHORTCUTS_FILE"
        log_export "keyboard-shortcuts.yaml"
    fi
fi

echo ""
echo "Found: ${#domain_order[@]} domains with shortcuts"
echo ""
