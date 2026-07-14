#!/bin/bash
# ============================================================================
# Login Items Sync
# ============================================================================
#
# Usage:
#   ./scripts/login-items.sh --export   # system -> config/login-items.yaml
#   ./scripts/login-items.sh --apply    # config -> system
#   ./scripts/login-items.sh --check    # report drift
#
# ---------------------------------------------------------------------------
# Scope and limits — read this before trusting it
# ---------------------------------------------------------------------------
#
# This covers only the *legacy* login items that System Events can see and set
# (System Settings > General > Login Items > "Open at Login").
#
# It does NOT cover modern SMAppService registrations — the "launch at login"
# toggle inside an app's own preferences. Those are owned by the app and cannot
# be set from here. Hammerspoon and Thaw are examples: the README tells you to
# enable their toggles by hand, and that is still required.
#
# So treat this as "most of the way there", not a complete restore. Anything
# missing after a login-items apply is probably an in-app toggle.
#
# Requires Automation permission for System Events (macOS prompts on first run).
#
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"
ITEMS_FILE="$CONFIG_DIR/config/login-items.yaml"

MODE=""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
DIM='\033[2m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

for arg in "$@"; do
    case $arg in
        --export) MODE=export ;;
        --apply) MODE=apply ;;
        --check) MODE=check ;;
        -h|--help) sed -n '2,28p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    esac
done
[[ -n "$MODE" ]] || { log_error "Specify --export, --apply or --check"; exit 1; }

# ----------------------------------------------------------------------------
# Read current login items as "name<TAB>path"
# ----------------------------------------------------------------------------
read_system_items() {
    osascript <<'EOF' 2>/dev/null
tell application "System Events"
  set out to ""
  repeat with li in login items
    try
      set p to path of li
    on error
      set p to "missing value"
    end try
    set out to out & (name of li) & tab & p & linefeed
  end repeat
  return out
end tell
EOF
}

# ~ for portability across accounts
collapse_home() { sed "s|^$HOME|~|"; }
expand_home() { sed "s|^~|$HOME|"; }

parse_tracked() {
    [[ -f "$ITEMS_FILE" ]] || return 0
    local name="" path=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+name:[[:space:]]*\"?([^\"]+)\"?[[:space:]]*$ ]]; then
            name="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^[[:space:]]+path:[[:space:]]*\"?([^\"]+)\"?[[:space:]]*$ ]]; then
            path="${BASH_REMATCH[1]}"
            [[ -n "$name" ]] && printf '%s\t%s\n' "$name" "$path"
            name="" path=""
        fi
    done < "$ITEMS_FILE"
}

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
read_system_items > "$TMP/system_raw"

if [[ ! -s "$TMP/system_raw" ]] && [[ "$MODE" != "apply" ]]; then
    log_error "Could not read login items."
    echo -e "${DIM}    System Events needs Automation permission (System Settings >"
    echo -e "    Privacy & Security > Automation). macOS prompts on first run.${NC}"
    exit 1
fi

echo ""
log_info "Login items: $MODE"
echo ""

case "$MODE" in
export)
    : > "$TMP/out"
    stale=0
    while IFS=$'\t' read -r name path; do
        [[ -z "$name" ]] && continue
        # macOS reports "missing value" when the target app is gone. Amethyst
        # was exactly this: a login item pointing at a deleted app. Don't
        # propagate that to a new machine.
        if [[ "$path" == "missing value" || ! -e "$path" ]]; then
            log_warn "skipping '$name' — target missing ($path)"
            ((stale++))
            continue
        fi
        printf '%s\t%s\n' "$name" "$(echo "$path" | collapse_home)" >> "$TMP/out"
    done < "$TMP/system_raw"

    {
        echo "# Login Items"
        echo "#"
        echo "# Managed by scripts/login-items.sh (--export / --apply / --check)."
        echo "#"
        echo "# Only legacy System Events login items. Apps that register via"
        echo "# SMAppService (their own 'launch at login' toggle — e.g. Hammerspoon,"
        echo "# Thaw) are NOT captured here and must still be enabled by hand."
        echo ""
        while IFS=$'\t' read -r name path; do
            echo "- name: \"$name\""
            echo "  path: \"$path\""
        done < "$TMP/out"
    } > "$ITEMS_FILE"

    log_ok "exported $(wc -l < "$TMP/out" | tr -d ' ') login items"
    [[ $stale -gt 0 ]] && log_warn "$stale stale item(s) skipped — remove them in System Settings"
    ;;

check)
    parse_tracked | sort > "$TMP/tracked"
    # NF guards the trailing blank line osascript emits, which would otherwise
    # become a phantom "" entry and report drift forever.
    awk -F'\t' 'NF && $1 != "" && $2 != "missing value"' "$TMP/system_raw" \
        | while IFS=$'\t' read -r n p; do
            [[ -z "$n" ]] && continue
            printf '%s\t%s\n' "$n" "$(echo "$p" | collapse_home)"
        done | sort > "$TMP/current"

    if diff -q "$TMP/tracked" "$TMP/current" >/dev/null 2>&1; then
        log_ok "login items in sync ($(wc -l < "$TMP/tracked" | tr -d ' ') items)"
        exit 0
    fi
    log_warn "login items drift"
    comm -13 "$TMP/tracked" "$TMP/current" | sed 's/^/    + present, untracked: /'
    comm -23 "$TMP/tracked" "$TMP/current" | sed 's/^/    - tracked, not present: /'
    exit 1
    ;;

apply)
    [[ -f "$ITEMS_FILE" ]] || { log_error "No $ITEMS_FILE — run --export first"; exit 1; }
    added=0 skipped=0
    while IFS=$'\t' read -r name path; do
        [[ -z "$name" ]] && continue
        real_path="$(echo "$path" | expand_home)"
        if [[ ! -e "$real_path" ]]; then
            log_warn "$name: not installed at $real_path — skipping"
            ((skipped++)); continue
        fi
        if awk -F'\t' -v n="$name" '$1==n {found=1} END {exit !found}' "$TMP/system_raw"; then
            echo -e "${DIM}  = $name already a login item${NC}"
            continue
        fi
        if osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"$real_path\", hidden:false}" >/dev/null 2>&1; then
            echo -e "${GREEN}  +${NC} $name"
            ((added++))
        else
            log_warn "$name: failed to add"
        fi
    done < <(parse_tracked)
    log_ok "added $added login item(s), skipped $skipped"
    echo -e "${DIM}    Apps with their own 'launch at login' toggle (Hammerspoon, Thaw)"
    echo -e "    still need it enabled in their preferences.${NC}"
    ;;
esac
echo ""
