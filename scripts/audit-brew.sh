#!/bin/bash
# ============================================================================
# Homebrew Drift Audit
# ============================================================================
#
# Compares the curated Brewfile against installed Homebrew packages.
#
# Usage:
#   ./scripts/audit-brew.sh
#
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"
BREWFILE="$CONFIG_DIR/Brewfile"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

normalize_cask_name() {
    case "$1" in
        docker-desktop) echo "docker" ;;
        logi-options+) echo "logi-options-plus" ;;
        *) echo "$1" ;;
    esac
}

normalize_formula_name() {
    local formula="$1"
    echo "${formula##*/}"
}

print_section() {
    local title="$1"
    local file="$2"
    local count

    count=$(wc -l < "$file" | tr -d ' ')
    if [[ "$count" -eq 0 ]]; then
        log_success "$title: none"
    else
        log_warning "$title: $count"
        sed 's/^/  - /' "$file"
    fi
}

if ! command -v brew >/dev/null 2>&1; then
    log_error "Homebrew is not installed"
    exit 1
fi

if [[ ! -f "$BREWFILE" ]]; then
    log_error "Brewfile not found: $BREWFILE"
    exit 1
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

declared_taps="$TMP_DIR/declared_taps"
installed_taps="$TMP_DIR/installed_taps"
missing_taps="$TMP_DIR/missing_taps"
extra_taps="$TMP_DIR/extra_taps"

declared_formulae="$TMP_DIR/declared_formulae"
declared_formula_names="$TMP_DIR/declared_formula_names"
installed_formulae="$TMP_DIR/installed_formulae"
missing_formulae="$TMP_DIR/missing_formulae"
extra_formulae="$TMP_DIR/extra_formulae"

declared_casks="$TMP_DIR/declared_casks"
declared_cask_names="$TMP_DIR/declared_cask_names"
installed_casks="$TMP_DIR/installed_casks"
missing_casks="$TMP_DIR/missing_casks"
extra_casks="$TMP_DIR/extra_casks"

awk -F'"' '/^[[:space:]]*tap[[:space:]]+"/ { print $2 }' "$BREWFILE" | sort -u > "$declared_taps"
brew tap 2>/dev/null | sort -u > "$installed_taps"
comm -23 "$declared_taps" "$installed_taps" > "$missing_taps"
comm -13 "$declared_taps" "$installed_taps" > "$extra_taps"

awk -F'"' '/^[[:space:]]*brew[[:space:]]+"/ { print $2 }' "$BREWFILE" | sort -u > "$declared_formulae"
while IFS= read -r formula; do
    normalize_formula_name "$formula"
done < "$declared_formulae" | sort -u > "$declared_formula_names"

brew leaves 2>/dev/null | while IFS= read -r formula; do
    normalize_formula_name "$formula"
done | sort -u > "$installed_formulae"

: > "$missing_formulae"
while IFS= read -r formula; do
    name=$(normalize_formula_name "$formula")
    if ! brew list "$formula" >/dev/null 2>&1 && ! brew list "$name" >/dev/null 2>&1; then
        echo "$formula" >> "$missing_formulae"
    fi
done < "$declared_formulae"
sort -u "$missing_formulae" -o "$missing_formulae"
comm -23 "$installed_formulae" "$declared_formula_names" > "$extra_formulae"

awk -F'"' '/^[[:space:]]*cask[[:space:]]+"/ { print $2 }' "$BREWFILE" | sort -u > "$declared_casks"
while IFS= read -r cask; do
    normalize_cask_name "$cask"
done < "$declared_casks" | sort -u > "$declared_cask_names"

brew list --cask 2>/dev/null | while IFS= read -r cask; do
    normalize_cask_name "$cask"
done | sort -u > "$installed_casks"

: > "$missing_casks"
while IFS= read -r cask; do
    if ! brew list --cask "$cask" >/dev/null 2>&1; then
        echo "$cask" >> "$missing_casks"
    fi
done < "$declared_casks"
sort -u "$missing_casks" -o "$missing_casks"
comm -23 "$installed_casks" "$declared_cask_names" > "$extra_casks"

echo ""
log_info "Auditing Homebrew state against $BREWFILE"
echo ""

print_section "Missing taps declared in Brewfile" "$missing_taps"
print_section "Installed taps not declared in Brewfile" "$extra_taps"
echo ""
print_section "Missing formulae declared in Brewfile" "$missing_formulae"
print_section "Installed formula leaves not declared in Brewfile" "$extra_formulae"
echo ""
print_section "Missing casks declared in Brewfile" "$missing_casks"
print_section "Installed casks not declared in Brewfile" "$extra_casks"
echo ""

drift_count=$(
    cat "$missing_taps" "$extra_taps" \
        "$missing_formulae" "$extra_formulae" \
        "$missing_casks" "$extra_casks" | wc -l | tr -d ' '
)

if [[ "$drift_count" -eq 0 ]]; then
    log_success "Homebrew state matches Brewfile"
    exit 0
else
    log_warning "Homebrew drift detected"
    echo "  - Install missing declared packages: ./scripts/brew_install_all.sh"
    echo "  - Add intentional extras to Brewfile"
    echo "  - Uninstall stale extras with: brew uninstall <name>"
    exit 1
fi
