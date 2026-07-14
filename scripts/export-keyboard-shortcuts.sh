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
RED='\033[0;31m'
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
# VALIDATION
# ============================================================================
#
# A well-formed shortcut is zero or more modifiers (@ ~ ^ $) followed by
# exactly one ASCII key character.
#
# Why this guard exists: `defaults find` renders a non-ASCII key (Tab, arrows,
# Escape) as a \Uxxxx escape. This script captures that text verbatim, and
# apply-keyboard-shortcuts.sh feeds it to PlistBuddy — which strips the
# backslash rather than decoding the escape, turning "^⇥" into the literal
# six-character ASCII string "^U21e5". The round trip is then stable on a
# destroyed value, so nothing ever reports a problem.
#
# That is exactly what happened to Messenger's ("Archon") Next/Previous Chat
# bindings: commit df07558 held the correct "^\U21e5", apply ran, and 20 seconds
# later f5086cb committed "^U21e5" as ground truth.
#
# Neither script can currently round-trip unicode, so refuse to export a
# shortcut we would corrupt instead of silently committing a broken binding.
# If you need a Tab/arrow/Escape binding, both scripts need a real fix first:
# export via `plutil -convert xml1` (which emits true UTF-8) rather than parsing
# `defaults find` text, and have apply write real unicode instead of PlistBuddy.

declare -a INVALID_SHORTCUTS=()

validate_shortcut() {
    local domain="$1" name="$2" value="$3"
    /usr/bin/python3 - "$value" <<'PY'
import sys
v = sys.argv[1]
key = v.lstrip("@~^$")
if len(key) == 1 and ord(key) < 128:
    sys.exit(0)
sys.exit(1)
PY
    if [[ $? -ne 0 ]]; then
        INVALID_SHORTCUTS+=("${domain} / ${name} = \"${value}\"")
        return 1
    fi
    return 0
}

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

        # Refuse to record anything we cannot round-trip (see VALIDATION above).
        validate_shortcut "$current_domain" "$name" "$shortcut" || continue

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

# Fail loudly rather than committing a shortcut we know we would corrupt.
if [[ ${#INVALID_SHORTCUTS[@]} -gt 0 ]]; then
    echo -e "${RED}[ERROR]${NC} Refusing to export ${#INVALID_SHORTCUTS[@]} shortcut(s) that cannot be round-tripped:"
    for s in "${INVALID_SHORTCUTS[@]}"; do
        echo "    $s"
    done
    echo ""
    echo -e "${DIM}    A shortcut must be modifiers (@ ~ ^ \$) plus exactly one ASCII key."
    echo -e "    A multi-character key means it was already corrupted by a previous"
    echo -e "    apply/export cycle; a non-ASCII key (Tab/arrows/Escape) cannot survive"
    echo -e "    PlistBuddy, which strips the backslash instead of decoding \\Uxxxx."
    echo -e "    See the VALIDATION comment in this script for the real fix.${NC}"
    echo ""
    exit 1
fi

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
