#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Smart Search
# @raycast.mode silent
# @raycast.packageName Search

# Optional parameters:
# @raycast.icon 🔍
# @raycast.description Copy selection, then open Linear / GitHub / URL / Google Search based on its content
# @raycast.author joshlebed
# @raycast.authorURL https://github.com/joshlebed

# Documentation:
# Bind to cmd+g in Raycast (and disable the old KM cmd+g macro). On trigger:
#   1. Copies the current selection
#   2. Routes the clipboard contents:
#        https?://...           -> open as URL
#        NS-790 (whitelisted prefixes) -> linear.app/<workspace>/issue/<ID>
#        #4953                  -> app.graphite.com/github/pr/<default repo>/4953
#        domain.tld[/path]      -> open as URL (auto-prefixes https://)
#        chrome://...           -> open in Chrome (internal pages)
#        scheme:rest            -> open in the registered app (spotify:, slack://, mailto:, ...)
#        anything else          -> Google search
#
# Latency budget (measured). Copy + wait + routing all happen in ONE osascript
# process; this script only forks `open` at the end.
#
#     osascript start        40ms   fixed
#     CGEvent cmd+c           0ms   was ~90ms via System Events
#     app writes clipboard   29ms   native; Electron is far slower, hence the poll
#     routing                ~0ms   was +30ms when it shelled out to python3
#     open -> Velja -> Chrome 57ms  Velja earns this (routes linear.app to the app)
#
# Two rewrites got it from ~330ms to ~130ms:
#
#   1. Sending cmd+c through `System Events` cost ~90ms in Apple Event round
#      trip. CGEventPost does the same thing in-process for ~0ms. osascript is
#      still the process posting the event, so the Accessibility grant this
#      needs is the same one it already had -- no new TCC identity.
#   2. Routing and percent-encoding moved into the same JXA process, which
#      removes a python3 spawn (~30ms) from the Google path.
#
# Reliability: this used to be `keystroke c` + `sleep 0.15`, which was a race.
# The osascript round trip alone ate ~130ms of that budget, leaving the target
# app ~150ms to write to the pasteboard. Native apps make it; Electron apps
# (Slack, Linear, Claude, Discord, Cursor) route copy through renderer -> IPC ->
# main and frequently do not. On a miss `pbpaste` returned the PREVIOUS
# clipboard, so the script re-opened the last URL -- and Chrome just refocuses
# that tab, which reads as "cmd+g did nothing". Now we snapshot
# NSPasteboard.changeCount and poll until it actually increments: returns the
# instant the copy lands, tolerates a slow app up to 1.2s, and a counter that
# never moves proves the copy failed instead of silently acting on stale text.

export LC_CTYPE=UTF-8

LINEAR_WORKSPACE="niteshift"
LINEAR_TEAM_PREFIXES="NS" # pipe-separated whitelist, e.g. "NS|ENG"
GITHUB_DEFAULT_REPO="niteshiftdev/niteshift"

LOG="${HOME}/Library/Logs/smart-search.log"

result="$(osascript -l JavaScript - "$LINEAR_WORKSPACE" "$LINEAR_TEAM_PREFIXES" "$GITHUB_DEFAULT_REPO" <<'JXA'
ObjC.import("AppKit");
ObjC.import("CoreGraphics");
ObjC.import("ApplicationServices");

function run(argv) {
  var WORKSPACE = argv[0], PREFIXES = argv[1], REPO = argv[2];

  // Probe the Accessibility zero-copy path, but do NOT act on it yet.
  //
  // Reading AXSelectedText off the focused element takes ~0.1ms and would skip
  // the clipboard entirely -- no copy race, no Electron variability, and it
  // would stop clobbering the clipboard. It currently returns
  // kAXErrorCannotComplete (-25204) when tested from a terminal, but Raycast
  // holds a real Accessibility grant and may do better. So: log whether it
  // WOULD have worked, and switch the fast path on once the log says it is
  // reliably `ax=hit` in real use. Costs ~0.1ms to ask.
  var ax = "miss";
  try {
    var sw = $.AXUIElementCreateSystemWide();
    var f = Ref();
    if ($.AXUIElementCopyAttributeValue(sw, $("AXFocusedUIElement"), f) === 0) {
      var s = Ref();
      if ($.AXUIElementCopyAttributeValue(f[0], $("AXSelectedText"), s) === 0) {
        var v = ObjC.unwrap(s[0]);
        ax = (v && v.length) ? "hit" : "empty";
      }
    }
  } catch (e) { ax = "err"; }

  // Snapshot the pasteboard generation BEFORE the copy. Anything landing after
  // this point is provably the new selection, not a leftover.
  var pb = $.NSPasteboard.generalPasteboard;
  var before = pb.changeCount;

  var CMD_FLAG = 1048576;             // kCGEventFlagMaskCommand
  var SESSION_TAP = 2;                // kCGAnnotatedSessionEventTap: measured
                                      // 29ms to land vs 84ms for kCGHIDEventTap
  var KEY_C = 8;                      // kVK_ANSI_C
  var src = $.CGEventSourceCreate(1); // kCGEventSourceStateCombinedSessionState
  var down = $.CGEventCreateKeyboardEvent(src, KEY_C, true);
  $.CGEventSetFlags(down, CMD_FLAG);
  var up = $.CGEventCreateKeyboardEvent(src, KEY_C, false);
  $.CGEventSetFlags(up, CMD_FLAG);
  $.CGEventPost(SESSION_TAP, down);
  $.CGEventPost(SESSION_TAP, up);

  var t0 = $.NSDate.date.timeIntervalSince1970;
  var deadline = t0 + 1.2;
  var changed = false;
  while ($.NSDate.date.timeIntervalSince1970 < deadline) {
    if (pb.changeCount !== before) { changed = true; break; }
    $.NSThread.sleepForTimeInterval(0.006);
  }
  var ms = Math.round(($.NSDate.date.timeIntervalSince1970 - t0) * 1000);

  // Fixed 6-line protocol: status / route / url / opener / fallback / preview.
  // URLs never contain whitespace by construction, and the preview is
  // flattened, so the bash side can split on newlines without forking.
  function emit(status, route, url, opener, fallback, preview) {
    return [status + " " + ms + " " + ax, route, url || "", opener || "default",
            fallback || "", preview || ""].join("\n");
  }

  if (!changed) return emit("STALE", "abort/no-copy");
  var raw = ObjC.unwrap(pb.stringForType($.NSPasteboardTypeString));
  if (raw == null) return emit("NOTEXT", "abort/non-text");

  var input = raw.replace(/^\s+/, "").replace(/\s+$/, "");
  var preview = input.replace(/\s+/g, " ").slice(0, 120);
  if (!input) return emit("EMPTY", "abort/empty", "", "", "", preview);

  var google = "https://www.google.com/search?q=" +
               encodeURIComponent(input).replace(/%20/g, "+");

  // 1. URL with explicit scheme
  if (/^https?:\/\/\S+$/.test(input)) return emit("OK", "url", input, "default", "", preview);

  // 2. Linear ticket (whitelisted team prefixes only, normalized to uppercase)
  var ticket = input.toUpperCase();
  if (new RegExp("^(" + PREFIXES + ")-[0-9]+$").test(ticket)) {
    return emit("OK", "linear", "https://linear.app/" + WORKSPACE + "/issue/" + ticket,
                "default", "", ticket);
  }

  // 3. GitHub PR/issue in the default repo -> open in Graphite
  if (/^#[0-9]+$/.test(input)) {
    return emit("OK", "graphite", "https://app.graphite.com/github/pr/" + REPO + "/" + input.slice(1),
                "default", "", preview);
  }

  // 4. Bare domain or domain/path (no scheme, no spaces)
  if (/^[a-zA-Z0-9][a-zA-Z0-9.-]*\.[a-zA-Z]{2,}(\/\S*)?$/.test(input)) {
    return emit("OK", "url/implicit-https", "https://" + input, "default", "", preview);
  }

  // 5. Chrome internal page -> hand straight to Chrome.
  //    Must come before rule 6: nothing claims the bare `chrome:` scheme in
  //    LaunchServices (only `google-chrome:`), so plain `open` fails and these
  //    would fall through to a Google search. `open -a` bypasses the lookup.
  if (/^chrome:\/\/\S+$/.test(input)) return emit("OK", "chrome-internal", input, "chrome", "", preview);

  // 6. Custom URL scheme -> let macOS open the registered app (spotify:,
  //    slack://, zoommtg://, mailto:, vscode://). We cannot know here whether
  //    anything claims the scheme, so hand bash the Google URL as a fallback to
  //    use when `open` exits non-zero.
  if (/^[a-zA-Z][a-zA-Z0-9+.-]*:\S+$/.test(input)) {
    return emit("OK", "scheme", input, "default", google, preview);
  }

  // 7. Fallback: Google search
  return emit("OK", "google", google, "default", "", preview);
}
JXA
)"

if [ -z "$result" ]; then
    echo "Smart Search failed (osascript produced no output)"
    exit 1
fi

# Split the 6-line protocol using parameter expansion only -- no forks, and
# bash 3.2 (what macOS ships) has no readarray.
rest="$result"
next() { field="${rest%%$'\n'*}"; rest="${rest#*$'\n'}"; }
next; statusline="$field"
next; route="$field"
next; url="$field"
next; opener="$field"
next; fallback="$field"
next; preview="$field"

read -r status wait_ms ax <<<"$statusline"

log() {
    printf '%s  copy=%-6s wait=%-6s ax=%-5s %-19s %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" "$status" "${wait_ms}ms" "$ax" "$1" "$2" >>"$LOG"
    if [ "$(wc -l <"$LOG" 2>/dev/null || echo 0)" -gt 2000 ]; then
        tail -n 1000 "$LOG" >"${LOG}.tmp" && mv "${LOG}.tmp" "$LOG"
    fi
}

case "$status" in
    STALE)
        # Nothing was copied: no selection, or the app ignored cmd+c. Acting on
        # the clipboard here would open whatever was last copied.
        log "$route" ""
        echo "Nothing copied — is anything selected?"
        exit 0
        ;;
    NOTEXT)
        log "$route" ""
        echo "Selection is not text"
        exit 0
        ;;
    EMPTY)
        log "$route" ""
        echo "Selection is empty"
        exit 0
        ;;
esac

if [ "$opener" = "chrome" ]; then
    log "$route" "$preview"
    open -a "Google Chrome" "$url"
    echo "Opening in Chrome: $url"
elif [ -n "$fallback" ]; then
    # Rule 6: unknown scheme -> `open` exits non-zero, fall through to Google.
    if open "$url" 2>/dev/null; then
        log "$route" "$preview"
        echo "Opening: $url"
    else
        log "google/scheme-miss" "$preview"
        open "$fallback"
        echo "Searching Google"
    fi
else
    log "$route" "$preview"
    open "$url"
    case "$route" in
        linear)   echo "Opening Linear: $preview" ;;
        graphite) echo "Opening Graphite: $url" ;;
        google)   echo "Searching Google" ;;
        *)        echo "Opening URL" ;;
    esac
fi
