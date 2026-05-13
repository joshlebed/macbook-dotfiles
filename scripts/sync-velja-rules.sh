#!/usr/bin/env bash
# ============================================================================
# sync-velja-rules.sh — sync Velja rules between this repo and the running app
# ============================================================================
#
# Velja stores rules in a sandboxed plist at:
#   ~/Library/Containers/com.sindresorhus.Velja/Data/Library/Preferences/com.sindresorhus.Velja.plist
# under the `rules` key, as an ARRAY OF JSON STRINGS (each entry is a
# stringified rule object). This script handles serialization both directions
# plus the quit → flush cfprefsd → edit → flush → restart dance required
# because cfprefsd caches plists in memory and will otherwise clobber direct
# file writes when Velja relaunches.
#
# Usage:
#   ./scripts/sync-velja-rules.sh apply               # repo → system (default)
#   ./scripts/sync-velja-rules.sh apply --no-restart  # apply without relaunch
#   ./scripts/sync-velja-rules.sh export              # system → repo
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"
SRC="$CONFIG_DIR/velja/rules.json"
PLIST="$HOME/Library/Containers/com.sindresorhus.Velja/Data/Library/Preferences/com.sindresorhus.Velja.plist"

cmd="${1:-apply}"
no_restart=false
for arg in "${@:2}"; do
  [ "$arg" = "--no-restart" ] && no_restart=true
done

velja_running() {
  pgrep -f "/Velja.app/" >/dev/null 2>&1
}

quit_velja() {
  osascript -e 'quit app "Velja"' >/dev/null 2>&1 || true
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    velja_running || return 0
    sleep 1
  done
  echo "ERROR: Velja did not exit cleanly within 10s" >&2
  return 1
}

flush_cfprefsd() {
  killall cfprefsd 2>/dev/null || true
}

require_plist() {
  if [ ! -f "$PLIST" ]; then
    echo "ERROR: Velja plist not found at $PLIST" >&2
    echo "Launch Velja at least once to create it." >&2
    exit 1
  fi
}

case "$cmd" in
  apply)
    [ -f "$SRC" ] || { echo "ERROR: source not found: $SRC" >&2; exit 1; }
    require_plist

    # Validate source JSON
    python3 - "$SRC" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
assert isinstance(d.get('rules'), list), "source must contain a 'rules' array"
for i, r in enumerate(d['rules']):
    assert isinstance(r, dict), f"rule {i} is not an object"
print(f"Source: {len(d['rules'])} rule(s)")
PY

    restart=true
    velja_running || restart=false
    $no_restart && restart=false

    if velja_running; then
      echo "Quitting Velja..."
      quit_velja || exit 1
    fi

    ts="$(date +%Y%m%d-%H%M%S)"
    cp "$PLIST" "$PLIST.bak.$ts"
    echo "Backup: $PLIST.bak.$ts"

    flush_cfprefsd
    sleep 1

    # Rewrite only the `rules` key; preserve every other preference.
    python3 - "$SRC" "$PLIST" <<'PY'
import json, plistlib, sys
src = json.load(open(sys.argv[1]))
with open(sys.argv[2], 'rb') as f:
    p = plistlib.load(f)
p['rules'] = [
    json.dumps(r, sort_keys=True, separators=(',', ':'), ensure_ascii=False)
    for r in src['rules']
]
with open(sys.argv[2], 'wb') as f:
    plistlib.dump(p, f, fmt=plistlib.FMT_BINARY)
print(f"Wrote {len(p['rules'])} rule(s) to plist")
PY

    plutil -lint "$PLIST"
    flush_cfprefsd
    sleep 1

    if $restart; then
      echo "Relaunching Velja..."
      open -a Velja
    fi
    echo "apply complete"
    ;;

  export)
    require_plist
    mkdir -p "$(dirname "$SRC")"
    python3 - "$SRC" "$PLIST" <<'PY'
import json, plistlib, sys
dst, plist_path = sys.argv[1], sys.argv[2]
with open(plist_path, 'rb') as f:
    p = plistlib.load(f)
rules = [json.loads(s) for s in p.get('rules', [])]
out = {"rules": rules, "version": "3.1.1"}
with open(dst, 'w') as f:
    json.dump(out, f, indent=2, ensure_ascii=False)
    f.write("\n")
print(f"Wrote {len(rules)} rule(s) to {dst}")
PY
    echo "export complete: $SRC"
    ;;

  *)
    echo "Usage: $0 {apply|export} [--no-restart]" >&2
    exit 2
    ;;
esac
