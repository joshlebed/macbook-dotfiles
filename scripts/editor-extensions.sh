#!/bin/bash
# ============================================================================
# Editor Extensions Sync (VS Code + Cursor)
# ============================================================================
#
# Usage:
#   ./scripts/editor-extensions.sh --export    # system -> repo
#   ./scripts/editor-extensions.sh --install   # repo -> system
#   ./scripts/editor-extensions.sh --check     # report drift, exit 1 if any
#
# ---------------------------------------------------------------------------
# Why this isn't in the Brewfile
# ---------------------------------------------------------------------------
#
# `brew bundle` supports `vscode "publisher.ext"` lines, and `brew bundle dump`
# will happily generate them — but it shells out to whatever `code` resolves to
# on PATH. On this machine `code` is *Cursor* (/opt/homebrew/bin/code ->
# Cursor.app), so those lines would install Cursor's extensions into Cursor
# while claiming to describe VS Code. On a new Mac the winner of the PATH race
# decides, which is not something to leave to chance.
#
# The two editors also hold genuinely different sets (22 vs 38 here — Cursor has
# the anysphere.* extensions VS Code cannot use), so one list cannot describe
# both.
#
# Hence: two lists, two CLIs, addressed by absolute path. VS Code's CLI lives
# inside its app bundle and is NOT the `code` on PATH.
#
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"

VSCODE_CLI="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
CURSOR_CLI="/Applications/Cursor.app/Contents/Resources/app/bin/cursor"

VSCODE_LIST="$CONFIG_DIR/vscode/extensions-vscode.txt"
CURSOR_LIST="$CONFIG_DIR/vscode/extensions-cursor.txt"

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
        --install) MODE=install ;;
        --check) MODE=check ;;
        -h|--help)
            sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
    esac
done

if [[ -z "$MODE" ]]; then
    log_error "Specify --export, --install or --check"
    exit 1
fi

DRIFT=0

# editor_name, cli_path, list_file
handle_editor() {
    local name="$1" cli="$2" list="$3"

    if [[ ! -x "$cli" ]]; then
        log_warn "$name not installed — skipping"
        echo -e "${DIM}    (expected CLI at $cli)${NC}"
        return 0
    fi

    case "$MODE" in
        export)
            mkdir -p "$(dirname "$list")"
            local tmp
            tmp=$(mktemp)
            if ! "$cli" --list-extensions 2>/dev/null | sort -u > "$tmp"; then
                log_error "$name: --list-extensions failed"
                rm -f "$tmp"; return 1
            fi
            if [[ ! -s "$tmp" ]]; then
                log_warn "$name: reported zero extensions — refusing to write an empty list"
                rm -f "$tmp"; return 1
            fi
            if [[ -f "$list" ]] && cmp -s "$tmp" "$list"; then
                log_ok "$name: unchanged ($(wc -l < "$list" | tr -d ' ') extensions)"
            else
                cp "$tmp" "$list"
                log_ok "$name: exported $(wc -l < "$list" | tr -d ' ') extensions"
            fi
            rm -f "$tmp"
            ;;

        check)
            [[ -f "$list" ]] || { log_warn "$name: no tracked list yet"; return 0; }
            local tmp
            tmp=$(mktemp)
            "$cli" --list-extensions 2>/dev/null | sort -u > "$tmp"
            if cmp -s "$tmp" "$list"; then
                log_ok "$name: in sync ($(wc -l < "$list" | tr -d ' ') extensions)"
            else
                log_warn "$name: drift"
                comm -13 "$list" "$tmp" | sed 's/^/    + installed, untracked: /'
                comm -23 "$list" "$tmp" | sed 's/^/    - tracked, not installed: /'
                DRIFT=1
            fi
            rm -f "$tmp"
            ;;

        install)
            [[ -f "$list" ]] || { log_warn "$name: no tracked list at $list"; return 0; }
            local installed tmp missing
            tmp=$(mktemp)
            "$cli" --list-extensions 2>/dev/null | sort -u > "$tmp"
            missing=$(comm -23 "$list" "$tmp")
            if [[ -z "$missing" ]]; then
                log_ok "$name: all $(wc -l < "$list" | tr -d ' ') extensions already installed"
                rm -f "$tmp"; return 0
            fi
            local n=0
            while IFS= read -r ext; do
                [[ -z "$ext" ]] && continue
                if "$cli" --install-extension "$ext" >/dev/null 2>&1; then
                    echo -e "${GREEN}  +${NC} $ext"
                    ((n++))
                else
                    log_warn "$name: failed to install $ext"
                fi
            done <<< "$missing"
            log_ok "$name: installed $n extension(s)"
            rm -f "$tmp"
            ;;
    esac
}

echo ""
log_info "Editor extensions: $MODE"
echo ""

handle_editor "VS Code" "$VSCODE_CLI" "$VSCODE_LIST"
echo ""
handle_editor "Cursor" "$CURSOR_CLI" "$CURSOR_LIST"
echo ""

if [[ "$MODE" == "check" && $DRIFT -ne 0 ]]; then
    log_info "Run ./scripts/editor-extensions.sh --export to record these"
    exit 1
fi
exit 0
