#!/bin/bash
# ============================================================================
# Homebrew Drift Audit
# ============================================================================
#
# Compares the curated Brewfile against what is actually installed.
#
# Usage:
#   ./scripts/audit-brew.sh
#   ./scripts/audit-brew.sh --quiet   # exit code only
#
# ---------------------------------------------------------------------------
# Why this doesn't use `brew leaves` / `brew bundle dump`
# ---------------------------------------------------------------------------
#
# Both omit every third-party-tap formula — as does `brew info --json=v2
# --installed`, which returns only homebrew/core. All three hid the same 8
# packages here (graphite, terraform, k9s, supabase, infisical, nightlight, pup,
# shell-ai), which is exactly how they stayed undeclared. Installed state comes
# from the Cellar/Caskroom receipts via lib/brew-inventory.py instead.
#
# The other old failure was reporting apps installed outside Homebrew as
# "missing" — 7 false alarms, which is the fastest way to teach someone to
# ignore an audit. A declared cask whose app is present but unmanaged is now
# reported separately, as information rather than drift.
#
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"
BREWFILE="$CONFIG_DIR/Brewfile"
INVENTORY="$SCRIPT_DIR/lib/brew-inventory.py"
PYTHON="/usr/bin/python3"

QUIET=false
for arg in "$@"; do
    case $arg in
        -q|--quiet) QUIET=true ;;
        -h|--help)
            echo "Usage: $(basename "$0") [--quiet]"
            echo ""
            echo "Compares the Brewfile against installed taps/formulae/casks/App Store apps."
            echo "Exits non-zero on drift."
            exit 0
            ;;
    esac
done

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
DIM='\033[2m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_note() { echo -e "${DIM}[NOTE]${NC} $1"; }

say() { [[ "$QUIET" == true ]] || echo -e "$@"; }

command -v brew >/dev/null 2>&1 || { log_error "Homebrew is not installed"; exit 1; }
[[ -f "$BREWFILE" ]] || { log_error "Brewfile not found: $BREWFILE"; exit 1; }
[[ -f "$INVENTORY" ]] || { log_error "Missing $INVENTORY"; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ============================================================================
# Gather
# ============================================================================

# --- declared ---
awk -F'"' '/^[[:space:]]*tap[[:space:]]+"/  { print $2 }' "$BREWFILE" | sort -u > "$TMP/dec_taps"
awk -F'"' '/^[[:space:]]*brew[[:space:]]+"/ { print $2 }' "$BREWFILE" | sort -u > "$TMP/dec_formulae"
awk -F'"' '/^[[:space:]]*cask[[:space:]]+"/ { print $2 }' "$BREWFILE" | sort -u > "$TMP/dec_casks"
# mas "Name", id: 12345
sed -n 's/^[[:space:]]*mas[[:space:]]*"\(.*\)",[[:space:]]*id:[[:space:]]*\([0-9]*\).*/\2/p' "$BREWFILE" \
    | sort -u > "$TMP/dec_mas"

# --- installed ---
# homebrew/services is auto-tapped by brew itself and is not something a
# Brewfile declares, so it is not drift.
brew tap 2>/dev/null | grep -vxF "homebrew/services" | sort -u > "$TMP/ins_taps"
"$PYTHON" "$INVENTORY" --formulae | sort -u > "$TMP/ins_formulae"
"$PYTHON" "$INVENTORY" --casks    | sort -u > "$TMP/ins_casks"
"$PYTHON" "$INVENTORY" --apps     | sort -u > "$TMP/ins_apps"
if command -v mas >/dev/null 2>&1; then
    mas list 2>/dev/null | awk '{print $1}' | sort -u > "$TMP/ins_mas"
else
    : > "$TMP/ins_mas"
fi

# ============================================================================
# Compare
# ============================================================================

comm -23 "$TMP/dec_taps" "$TMP/ins_taps" > "$TMP/missing_taps"
comm -13 "$TMP/dec_taps" "$TMP/ins_taps" > "$TMP/extra_taps"

# A declared formula counts as present if it is installed at all — even as a
# dependency rather than on request (e.g. tmux arrives via tmuxai). Only
# genuinely absent ones are drift.
: > "$TMP/missing_formulae"
while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    short="${f##*/}"
    if ! brew list --formula --versions "$short" >/dev/null 2>&1; then
        echo "$f" >> "$TMP/missing_formulae"
    fi
done < "$TMP/dec_formulae"

# Extras: installed on request but undeclared. Compare on short names, since the
# Brewfile is tap-qualified but the comparison should not care.
sed 's|.*/||' "$TMP/dec_formulae" | sort -u > "$TMP/dec_formulae_short"
sed 's|.*/||' "$TMP/ins_formulae" | sort -u > "$TMP/ins_formulae_short"
comm -13 "$TMP/dec_formulae_short" "$TMP/ins_formulae_short" > "$TMP/extra_formulae"

sed 's|.*/||' "$TMP/dec_casks" | sort -u > "$TMP/dec_casks_short"
comm -23 "$TMP/dec_casks_short" "$TMP/ins_casks" > "$TMP/absent_casks"
comm -13 "$TMP/dec_casks_short" "$TMP/ins_casks" > "$TMP/extra_casks"

# Split "absent from the Caskroom" into genuinely missing vs installed by other
# means. lib/brew-inventory.py checks app bundles, pkg receipts and binaries —
# checking only for a .app would misreport every pkg-based cask (Office, Zoom,
# OneDrive, Okta Verify) and binary casks (codex) as missing.
: > "$TMP/missing_casks"
: > "$TMP/unmanaged_casks"
if [[ -s "$TMP/absent_casks" ]]; then
    # shellcheck disable=SC2046
    "$PYTHON" "$INVENTORY" --cask-presence $(tr '\n' ' ' < "$TMP/absent_casks") \
        > "$TMP/cask_presence" 2>/dev/null || : > "$TMP/cask_presence"
    while IFS= read -r c; do
        [[ -z "$c" ]] && continue
        evidence=$(awk -F'\t' -v t="$c" '$1==t {print $2; exit}' "$TMP/cask_presence")
        if [[ -n "$evidence" ]]; then
            echo "$c ($evidence present, installed outside Homebrew)" >> "$TMP/unmanaged_casks"
        else
            echo "$c" >> "$TMP/missing_casks"
        fi
    done < "$TMP/absent_casks"
fi

comm -23 "$TMP/dec_mas" "$TMP/ins_mas" > "$TMP/missing_mas"
comm -13 "$TMP/dec_mas" "$TMP/ins_mas" > "$TMP/extra_mas"

# ============================================================================
# Report
# ============================================================================

count() { wc -l < "$1" | tr -d ' '; }

section() {
    local title="$1" file="$2" level="${3:-warn}"
    local n; n=$(count "$file")
    if [[ "$n" -eq 0 ]]; then
        say "$(log_success "$title: none")"
    elif [[ "$level" == "note" ]]; then
        say "$(log_note "$title: $n")"
        [[ "$QUIET" == true ]] || sed 's/^/    - /' "$file"
    else
        say "$(log_warning "$title: $n")"
        [[ "$QUIET" == true ]] || sed 's/^/    - /' "$file"
    fi
}

say ""
say "$(log_info "Auditing Homebrew state against $BREWFILE")"
say ""
section "Declared taps not installed" "$TMP/missing_taps"
section "Installed taps not declared" "$TMP/extra_taps"
say ""
section "Declared formulae not installed" "$TMP/missing_formulae"
section "Installed on-request formulae not declared" "$TMP/extra_formulae"
say ""
section "Declared casks not installed" "$TMP/missing_casks"
section "Installed casks not declared" "$TMP/extra_casks"
section "Declared casks present but not Homebrew-managed" "$TMP/unmanaged_casks" note
say ""
if command -v mas >/dev/null 2>&1; then
    section "Declared App Store apps not installed" "$TMP/missing_mas"
    section "Installed App Store apps not declared" "$TMP/extra_mas" note
else
    say "$(log_note "mas not installed — App Store apps not audited")"
fi
say ""

# `unmanaged_casks` and `extra_mas` are informational and deliberately excluded:
# an app installed by hand still satisfies the Brewfile's intent on a new Mac,
# and Apple's preinstalled App Store apps are not worth declaring.
drift=$(cat "$TMP/missing_taps" "$TMP/extra_taps" \
            "$TMP/missing_formulae" "$TMP/extra_formulae" \
            "$TMP/missing_casks" "$TMP/extra_casks" \
            "$TMP/missing_mas" 2>/dev/null | wc -l | tr -d ' ')

if [[ "$drift" -eq 0 ]]; then
    say "$(log_success "Homebrew state matches Brewfile")"
    exit 0
else
    say "$(log_warning "Homebrew drift detected ($drift)")"
    say "  - Install declared-but-missing:  ./scripts/brew_install_all.sh"
    say "  - Add intentional extras to the Brewfile"
    say "  - Or remove stale ones: brew uninstall <name>"
    exit 1
fi
