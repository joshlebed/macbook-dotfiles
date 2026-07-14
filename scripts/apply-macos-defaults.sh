#!/bin/bash
# ============================================================================
# Apply macOS System Defaults
# ============================================================================
#
# Usage:
#   ./scripts/apply-macos-defaults.sh            # Apply
#   ./scripts/apply-macos-defaults.sh --dry-run  # Preview
#   ./scripts/apply-macos-defaults.sh --check    # Report differences, exit 1
#
# The scriptable half of mac-settings.md. Values were read off a configured
# machine rather than guessed, so this reproduces that setup rather than
# somebody's idea of sensible defaults.
#
# What is deliberately NOT here (and stays manual in mac-settings.md):
#   - Disabling system keyboard shortcuts (Spotlight, Launchpad, Mission
#     Control). These live in com.apple.symbolichotkeys as opaque numeric IDs
#     with binary values; writing them blind is a good way to break the
#     keyboard. App-level shortcuts are handled by apply-keyboard-shortcuts.sh.
#   - Screenshot shortcuts, Services shortcuts.
#   - Lock screen timing, wallpaper, screen saver.
#   - Login items — see scripts/login-items.sh.
#
# ============================================================================

set -uo pipefail

DRY_RUN=false
CHECK=false

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
log_set() { echo -e "${GREEN}[SET]${NC} $1"; }
log_diff() { echo -e "${YELLOW}[DIFF]${NC} $1"; }
log_dry() { echo -e "${CYAN}[DRY-RUN]${NC} $1"; }

for arg in "$@"; do
    case $arg in
        -n|--dry-run) DRY_RUN=true ;;
        -c|--check) CHECK=true ;;
        -h|--help) sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    esac
done

[[ "$(uname)" == "Darwin" ]] || { echo "macOS only"; exit 1; }

# domain|key|type|value|description
SETTINGS=(
    "-g|KeyRepeat|-int|2|Key repeat rate (fast)"
    "-g|InitialKeyRepeat|-int|15|Delay until repeat (short)"
    "-g|ApplePressAndHoldEnabled|-bool|false|Disable accent popup on key hold (repeat instead)"
    "-g|AppleShowScrollBars|-string|WhenScrolling|Show scroll bars only when scrolling"
    "-g|NSAutomaticSpellingCorrectionEnabled|-bool|false|Disable autocorrect"
    "-g|NSAutomaticCapitalizationEnabled|-bool|false|Disable auto-capitalisation"
    "com.apple.spaces|spans-displays|-bool|true|Displays have separate Spaces = OFF"
    "com.apple.dock|tilesize|-int|128|Dock size (large)"
    "com.apple.dock|orientation|-string|left|Dock on the left"
    "com.apple.dock|autohide|-bool|true|Auto-hide the Dock"
    "com.apple.universalaccess|reduceMotion|-bool|true|Reduce motion"
)

# `defaults read` prints booleans as 0/1, so normalise for comparison.
normalize() {
    case "$1" in
        true|1) echo 1 ;;
        false|0) echo 0 ;;
        *) echo "$1" ;;
    esac
}

echo ""
if [[ "$CHECK" == true ]]; then
    log_info "Checking macOS defaults..."
elif [[ "$DRY_RUN" == true ]]; then
    log_info "Dry run - previewing macOS defaults..."
else
    log_info "Applying macOS defaults..."
fi
echo ""

CHANGED=0
DIFFS=0
NEEDS_DOCK_RESTART=false

for row in "${SETTINGS[@]}"; do
    IFS='|' read -r domain key type value desc <<< "$row"

    current=$(defaults read "$domain" "$key" 2>/dev/null)
    want=$(normalize "$value")
    have=$(normalize "${current:-<unset>}")

    if [[ "$have" == "$want" ]]; then
        [[ "$CHECK" == true ]] && log_ok "$desc"
        continue
    fi

    if [[ "$CHECK" == true ]]; then
        log_diff "$desc (want $want, have $have)"
        ((DIFFS++))
        continue
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_dry "$desc: $have -> $want"
        ((CHANGED++))
        continue
    fi

    defaults write "$domain" "$key" "$type" "$value"
    log_set "$desc ($have -> $want)"
    ((CHANGED++))
    [[ "$domain" == "com.apple.dock" || "$domain" == "com.apple.spaces" ]] && NEEDS_DOCK_RESTART=true
done

# ----------------------------------------------------------------------------
# Night Shift
# ----------------------------------------------------------------------------
#
# Night Shift is NOT a `defaults` setting and cannot be synced as a plist. There
# is no com.apple.CoreBrightness user domain and nothing in ~/Library/Preferences
# — the settings are owned by the CoreBrightness daemon and reached only through
# Apple's private CoreBrightness.framework (CBBlueLightClient). Verified with
# otool: the nightlight binary links that private framework directly.
#
# So the CLI is the only sync mechanism, which is why nightlight is in the
# Brewfile: it is a dependency of this script, not a stray package.

NIGHTLIGHT_TEMP=50
NIGHTLIGHT_SCHEDULE="sunset to sunrise"

apply_night_shift() {
    if ! command -v nightlight >/dev/null 2>&1; then
        log_diff "nightlight not installed — skipping Night Shift"
        echo -e "${DIM}    Run ./scripts/brew_install_all.sh (Brewfile: smudge/smudge/nightlight)${NC}"
        return 0
    fi

    local cur_temp cur_sched
    cur_temp=$(nightlight temp 2>/dev/null | tr -d '[:space:]')
    cur_sched=$(nightlight schedule 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if [[ "$cur_temp" == "$NIGHTLIGHT_TEMP" ]]; then
        [[ "$CHECK" == true ]] && log_ok "Night Shift temperature ($NIGHTLIGHT_TEMP)"
    else
        if [[ "$CHECK" == true ]]; then
            log_diff "Night Shift temperature (want $NIGHTLIGHT_TEMP, have ${cur_temp:-?})"
            ((DIFFS++))
        elif [[ "$DRY_RUN" == true ]]; then
            log_dry "Night Shift temperature: ${cur_temp:-?} -> $NIGHTLIGHT_TEMP"
            ((CHANGED++))
        else
            nightlight temp "$NIGHTLIGHT_TEMP" >/dev/null 2>&1 \
                && log_set "Night Shift temperature ($NIGHTLIGHT_TEMP)" && ((CHANGED++))
        fi
    fi

    if [[ "$cur_sched" == "$NIGHTLIGHT_SCHEDULE" ]]; then
        [[ "$CHECK" == true ]] && log_ok "Night Shift schedule ($NIGHTLIGHT_SCHEDULE)"
    else
        if [[ "$CHECK" == true ]]; then
            log_diff "Night Shift schedule (want '$NIGHTLIGHT_SCHEDULE', have '${cur_sched:-?}')"
            ((DIFFS++))
        elif [[ "$DRY_RUN" == true ]]; then
            log_dry "Night Shift schedule: '${cur_sched:-?}' -> '$NIGHTLIGHT_SCHEDULE'"
            ((CHANGED++))
        else
            # `schedule start` is the CLI's name for sunset-to-sunrise.
            nightlight schedule start >/dev/null 2>&1 \
                && log_set "Night Shift schedule ($NIGHTLIGHT_SCHEDULE)" && ((CHANGED++))
        fi
    fi
}

apply_night_shift

echo ""
if [[ "$CHECK" == true ]]; then
    if [[ $DIFFS -eq 0 ]]; then
        log_ok "All macOS defaults match"
        exit 0
    fi
    log_diff "$DIFFS setting(s) differ — run ./scripts/apply-macos-defaults.sh"
    exit 1
fi

if [[ "$DRY_RUN" == true ]]; then
    echo "Would change: $CHANGED"
else
    echo "Changed: $CHANGED"
    if [[ "$NEEDS_DOCK_RESTART" == true ]]; then
        killall Dock 2>/dev/null || true
        log_info "Restarted Dock to apply Dock/Spaces changes"
    fi
    if [[ $CHANGED -gt 0 ]]; then
        echo ""
        log_info "Some settings (key repeat, scroll bars) only apply to apps launched afterwards."
        echo -e "${DIM}    Log out and back in for everything to take effect.${NC}"
        echo ""
        log_info "Still manual — see mac-settings.md:"
        echo -e "${DIM}    system keyboard shortcuts, screenshots, lock screen, wallpaper${NC}"
    fi
fi
echo ""
