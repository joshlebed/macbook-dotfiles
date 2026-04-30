# Hammerspoon Directional Window Switcher Debugging

This runbook is for debugging `.hammerspoon/init.lua`, the directional window
switcher bound to `F16` and `Shift+F16`.

The goal for a future agent: drive the experiment yourself. Add temporary logs,
reload Hammerspoon automatically, verify that logging is live, then ask the user
for one focused reproduction pass. Do not make the user paste console logs unless
Hammerspoon fails before file logging starts.

## Maintaining This Runbook

This doc is a living mirror of `init.lua`. When you change one, change the
other. Before reporting any debugging task complete:

- If you changed how candidates are built, scored, or filtered in `init.lua`,
  update the "Current Design" section here so it matches what the code actually
  does.
- If you discovered a new app-specific gotcha (an Electron app that is invisible
  to some Hammerspoon API, a window-server quirk, an OS behavior, a bundle id
  that misbehaves), record it under "Current Design" or "Interpreting Logs" so
  the next agent does not rediscover it from scratch.
- If you removed, renamed, or added a global helper (`wsDump`, `wsLogPath`,
  `wsDebugOn`, …) or a local in `init.lua` that this doc references
  (`ordered_windows`, `is_focus_candidate`, `app_info`, `frame_info`,
  `window_id`, `safe_value`, `sort_windows`, `REJECT_TITLE_PATTERNS`, …),
  search this file for the old name and update or remove every reference.
- If a code snippet here would no longer load against the current `init.lua`
  (it references a deleted local, or assumes a removed global), fix the
  snippet so a future agent can paste it in and have it work.
- Add a short entry to "Bugs Fixed" describing the bug and the fix, including
  the date. Do not delete old entries; future regressions are easier to spot
  with the history visible.

After editing, read the doc end-to-end once with the lens: could a fresh agent
who has never seen this codebase actually follow these instructions today?

## Runtime Facts

- Repo file: `/Users/joshlebed/.config/.hammerspoon/init.lua`
- Live Hammerspoon config: `~/.hammerspoon/init.lua`
- The live file is expected to be a symlink to the repo file.
- Hammerspoon CLI may not be on `PATH`. The bundled CLI is:

```bash
/Applications/Hammerspoon.app/Contents/Frameworks/hs/hs
```

Useful commands:

```bash
# Reload Hammerspoon without touching the GUI console.
open -g hammerspoon://reload

# Query the live process with the bundled CLI.
"/Applications/Hammerspoon.app/Contents/Frameworks/hs/hs" -c 'return wsDump()'

# Confirm Hammerspoon is running.
pgrep -fl Hammerspoon
```

Avoid using the Hammerspoon GUI console as the primary debug surface. During one
debug session, the console itself became a focus candidate and changed the
window list. Prefer CLI calls and file logs.

## Current Design

The switcher uses a single-stage candidate model. `init.lua` iterates
`hs.window.visibleWindows()` and runs each window through `is_focus_candidate`.
Anything that passes goes into the list, sorted by window center-X.

`is_focus_candidate` rejects:

- minimized windows
- non-standard AX windows (this also catches the 0×0/blank-role iTerm2
  stale-object case earlier versions of this code worried about)
- zero frame area
- Hammerspoon itself (`org.hammerspoon.Hammerspoon`)
- titles matching `REJECT_TITLE_PATTERNS` (`Find in page`, `MenuBarCover`)
- empty titles, unless the bundle id starts with `com.google.Chrome.app.`
  (Chrome app-mode windows with empty titles are allowed if they have a real
  app name and a standard nonzero window)

`hs.window.visibleWindows()` empirically returns only current-Space windows on
this machine, so we did not lose anything by dropping the filter.

### Why we removed `hs.window.filter`

Earlier versions ran a `hs.window.filter` and intersected its membership with
`hs.window.visibleWindows()`. The filter relies on per-app AX subscriptions and
silently drops some apps — Linear (`com.linear`) was the documented case: its
window was visible, standard, with a real title and a real frame, but never
appeared in `switcher:getWindows()`. The intersection then dropped Linear from
the switcher even though it was a perfectly valid focus target.

If you find yourself wanting to add a filter back, first check whether
`is_focus_candidate` already does what you need. If you genuinely need filter
membership (e.g. for event subscriptions), assume the filter does not see every
visible window and union, do not intersect.

### Known Chrome app behavior

- Chrome app windows can be valid focusable windows while reporting `title=""`.
- Examples observed:
  - `Niteshift`: `com.google.Chrome.app.ncgboinjakipfpjhkgpeoibgpgkedjba`
  - `Google Calendar`: `com.google.Chrome.app.kjbdgfilnfhdoflbpgamdcdgpehopbep`

### Known Electron / window-filter gap

- `hs.window.filter` does not track Linear (`com.linear`) at all. Other Electron
  apps may have the same problem. Do not treat filter membership as ground
  truth for "windows that exist".

## Invariants To Check

- Pressing right repeatedly should never bounce A -> B -> A -> B unless the user
  is also changing focus/window layout.
- The active candidate order should be stable across one repeated-key sequence.
- If `right` moves from index `N` to index `N+1`, the next `right` should start
  from that focused window's index in the current candidate list.
- A focused window that is visible and user-facing should usually appear in the
  active candidate list. If it does not, log why.
- No `0x0` frame, nonstandard role, empty-title non-Chrome-app, or Hammerspoon
  console window should be in the active candidate list.

## Fast Triage

Start with the current lightweight helper:

```bash
"/Applications/Hammerspoon.app/Contents/Frameworks/hs/hs" -c 'return wsDump()'
```

Look for:

- app names and bundle IDs of skipped windows
- empty titles
- duplicate windows with the same app/frame
- wrong center X ordering
- missing expected apps
- `candidate = false` if the helper is expanded to include rejected windows

If `wsDump()` already shows the skipped window in the active list, the issue is
probably focus behavior or changing candidate order, not membership.

If `wsDump()` does not show the skipped window, the next step depends on
whether the window appears in `hs.window.visibleWindows()`:

- If `visibleWindows()` does include it, the rejection is happening inside
  `is_focus_candidate`. Inspect the window's `title`, `bundleID`, `role`,
  `subrole`, `isStandard`, `frame.area`, and `isMinimized` to find which
  predicate is firing.
- If `visibleWindows()` does not include it, the gap is below us — Hammerspoon
  itself does not see the window. Check accessibility permissions, and check
  whether the window is on the current Space.

Add the temporary logging below to capture both lists side by side. If you
suspect a `hs.window.filter` interaction (e.g. comparing against an older
filter-based version), the snippets below show how to spin up a diagnostic
filter inline without changing production behavior.

## Temporary Logging Pattern

Add temporary instrumentation directly in `init.lua`, reload, reproduce, inspect
the file log, then remove the instrumentation. Keep production config quiet.

Use JSON-lines logs under:

```text
~/.hammerspoon/window-switcher-debug.log
```

Basic logger:

```lua
local DEBUG_LOG_PATH = hs.configdir .. "/window-switcher-debug.log"
local debug_enabled = true
local debug_session = os.date("!%Y%m%dT%H%M%SZ") .. "-" .. tostring(math.random(100000, 999999))

local function append_debug(event, payload)
  if not debug_enabled then return end

  payload = payload or {}
  payload.event = event
  payload.session = debug_session
  payload.time = os.date("%Y-%m-%d %H:%M:%S")
  payload.epoch = hs.timer.secondsSinceEpoch()

  local ok_json, line = pcall(function() return hs.json.encode(payload) end)
  if not ok_json then line = hs.inspect(payload) end

  local file = io.open(DEBUG_LOG_PATH, "a")
  if file then
    file:write(line .. "\n")
    file:close()
  end
end

_G.wsLogPath = function()
  return DEBUG_LOG_PATH
end

_G.wsClearLog = function()
  local file = io.open(DEBUG_LOG_PATH, "w")
  if file then file:close() end
  append_debug("log-cleared", { path = DEBUG_LOG_PATH })
  return DEBUG_LOG_PATH
end

_G.wsDebugOn = function()
  debug_enabled = true
  append_debug("debug-enabled", { path = DEBUG_LOG_PATH })
  return DEBUG_LOG_PATH
end

_G.wsDebugOff = function()
  append_debug("debug-disabled", { path = DEBUG_LOG_PATH })
  debug_enabled = false
  return DEBUG_LOG_PATH
end
```

Why file logs:

- The Hammerspoon console can affect focus and candidate selection.
- CLI/file logs let the agent inspect data directly.
- JSON-lines are easy to search with `rg` and compare across keypresses.

## Verbose Snapshot To Add Temporarily

When debugging candidate-set problems, log up to three lists:

- live visible list: `hs.window.visibleWindows()`
- final active list: `ordered_windows()`
- (optional) diagnostic filter list, if you want to compare what
  `hs.window.filter` would have included. Production no longer uses a filter,
  so this snippet creates one inline only for the snapshot.

Add or adapt helpers like these inside `init.lua`, where they can access local
functions such as `ordered_windows`, `sort_windows`, `window_id`, `app_info`,
`frame_info`, `is_focus_candidate`, and `REJECT_TITLE_PATTERNS`:

```lua
local function window_set_by_id(wins)
  local ids = {}
  for _, win in ipairs(wins or {}) do
    local id = window_id(win)
    if id then ids[id] = true end
  end
  return ids
end

local function describe_debug_window(win, memberships)
  if not win then return nil end

  local app = app_info(win)
  local frame = frame_info(win)
  local title = safe_value("", function() return win:title() or "" end)
  local id = window_id(win)

  return {
    id = id,
    app = app.name,
    bundleID = app.bundleID,
    title = title,
    role = safe_value("", function() return win:role() end),
    subrole = safe_value("", function() return win:subrole() end),
    isStandard = safe_value(false, function() return win:isStandard() end),
    isVisible = safe_value(false, function() return win:isVisible() end),
    isMinimized = safe_value(false, function() return win:isMinimized() end),
    frame = frame,
    centerX = frame.cx,
    candidate = is_focus_candidate(win),
    inRawFilter = memberships and memberships.raw and memberships.raw[id] or nil,
    inVisibleWindows = memberships and memberships.visible and memberships.visible[id] or nil,
    inFinal = memberships and memberships.final and memberships.final[id] or nil,
  }
end

local function describe_debug_windows(wins, memberships)
  local out = {}
  for index, win in ipairs(wins or {}) do
    local desc = describe_debug_window(win, memberships)
    if desc then
      desc.index = index
      table.insert(out, desc)
    end
  end
  return out
end

-- Optional: spin up a diagnostic filter just for snapshotting. Not used by
-- production focus-step logic; only here so we can compare what the filter
-- would have included against `hs.window.visibleWindows()`. Remove when done.
local diag_filter = hs.window.filter.new()
  :setDefaultFilter({})
  :setOverrideFilter({
    visible = true,
    currentSpace = true,
    rejectTitles = REJECT_TITLE_PATTERNS,
  })

local function debug_snapshot(label)
  local raw = sort_windows(diag_filter:getWindows())
  local visible = sort_windows(hs.window.visibleWindows())
  local final = ordered_windows()
  local memberships = {
    raw = window_set_by_id(raw),
    visible = window_set_by_id(visible),
    final = window_set_by_id(final),
  }

  return {
    label = label,
    focused = describe_debug_window(hs.window.focusedWindow(), memberships),
    counts = {
      raw = #raw,
      visible = #visible,
      final = #final,
    },
    rawWindows = describe_debug_windows(raw, memberships),
    visibleWindows = describe_debug_windows(visible, memberships),
    finalWindows = describe_debug_windows(final, memberships),
  }
end

_G.wsDumpVerbose = function(label)
  local data = debug_snapshot(label or "manual-dump")
  append_debug("manual-dump", data)
  return hs.inspect(data)
end
```

Useful CLI calls after adding this:

```bash
HS="/Applications/Hammerspoon.app/Contents/Frameworks/hs/hs"

open -g hammerspoon://reload
sleep 1
"$HS" -c 'wsClearLog(); wsDumpVerbose("baseline"); return wsLogPath()'
tail -n 5 ~/.hammerspoon/window-switcher-debug.log
```

## Focus-Step Logging

For directional-loop bugs, instrument `focus_step(direction)`.

Log before focusing:

- direction
- current window
- current index
- target window
- target index
- candidate count
- full snapshot
- previous switch summary
- loop suspect boolean

Then log actual focus after short delays:

- after 150ms
- after 500ms

The delay matters because macOS and Hammerspoon sometimes focus a different
window than the one requested, or update AX state after the focus call returns.

Template:

```lua
local switch_count = 0
local last_switch

local function focus_step(direction)
  switch_count = switch_count + 1

  local wins = ordered_windows()
  local before = hs.window.focusedWindow()
  local before_id = before and window_id(before) or nil

  if #wins == 0 then
    append_debug("switch-no-candidates", {
      switch = switch_count,
      direction = direction,
      snapshot = debug_snapshot("no-candidates"),
    })
    return
  end

  if not before then
    append_debug("switch-no-focused-window", {
      switch = switch_count,
      direction = direction,
      target = describe_debug_window(wins[1]),
      snapshot = debug_snapshot("no-focused-window"),
    })
    wins[1]:focus()
    return
  end

  local idx
  for i, win in ipairs(wins) do
    if window_id(win) == before_id then idx = i; break end
  end

  if not idx then
    append_debug("switch-focused-window-not-in-candidates", {
      switch = switch_count,
      direction = direction,
      before = describe_debug_window(before),
      target = describe_debug_window(wins[1]),
      snapshot = debug_snapshot("focused-missing"),
    })
    wins[1]:focus()
    return
  end

  local next_idx = direction == "east" and idx + 1 or idx - 1
  if next_idx < 1 or next_idx > #wins then
    append_debug("switch-boundary", {
      switch = switch_count,
      direction = direction,
      currentIndex = idx,
      candidateCount = #wins,
      before = describe_debug_window(before),
      snapshot = debug_snapshot("boundary"),
    })
    return
  end

  local target = wins[next_idx]
  local target_id = window_id(target)
  local loop_suspect = last_switch
    and last_switch.direction == direction
    and last_switch.before_id == target_id
    and last_switch.target_id == before_id

  append_debug("switch-attempt", {
    switch = switch_count,
    direction = direction,
    currentIndex = idx,
    targetIndex = next_idx,
    candidateCount = #wins,
    before = describe_debug_window(before),
    target = describe_debug_window(target),
    loopSuspect = loop_suspect or false,
    previousSwitch = last_switch,
    snapshot = debug_snapshot("switch-attempt"),
  })

  target:focus()

  last_switch = {
    switch = switch_count,
    direction = direction,
    before_id = before_id,
    target_id = target_id,
    currentIndex = idx,
    targetIndex = next_idx,
  }

  hs.timer.doAfter(0.15, function()
    append_debug("switch-after-150ms", {
      switch = switch_count,
      direction = direction,
      expectedTarget = describe_debug_window(target),
      focused = describe_debug_window(hs.window.focusedWindow()),
    })
  end)

  hs.timer.doAfter(0.50, function()
    append_debug("switch-after-500ms", {
      switch = switch_count,
      direction = direction,
      expectedTarget = describe_debug_window(target),
      focused = describe_debug_window(hs.window.focusedWindow()),
      snapshot = debug_snapshot("after-500ms"),
    })
  end)
end
```

## Filter Event Logging

For candidate-set churn, temporarily subscribe to window filter events. This
can produce lots of logs, so use it only during a short experiment. Production
no longer keeps a `hs.window.filter` alive, so this snippet creates one inline
just for the experiment — and reuses `diag_filter` if you already added one in
the snapshot helper above.

Caveat: the filter does not see every visible window (Linear and likely other
Electron apps are missing). Treat filter events as a partial signal, not as
ground truth for "which apps are present".

```lua
diag_filter = diag_filter or hs.window.filter.new()
  :setDefaultFilter({})
  :setOverrideFilter({
    visible = true,
    currentSpace = true,
    rejectTitles = REJECT_TITLE_PATTERNS,
  })

local function subscribe_debug_events()
  local events = {
    hs.window.filter.windowAllowed,
    hs.window.filter.windowRejected,
    hs.window.filter.windowCreated,
    hs.window.filter.windowDestroyed,
    hs.window.filter.windowMoved,
    hs.window.filter.windowFocused,
    hs.window.filter.windowUnfocused,
    hs.window.filter.windowTitleChanged,
    hs.window.filter.windowVisible,
    hs.window.filter.windowNotVisible,
    hs.window.filter.windowInCurrentSpace,
    hs.window.filter.windowNotInCurrentSpace,
    hs.window.filter.windowOnScreen,
    hs.window.filter.windowNotOnScreen,
    hs.window.filter.windowMinimized,
    hs.window.filter.windowUnminimized,
    hs.window.filter.windowsChanged,
  }

  diag_filter:subscribe(events, function(win, app_name, event)
    append_debug("filter-event", {
      filterEvent = event,
      appName = app_name,
      window = describe_debug_window(win),
    })
  end)
end

subscribe_debug_events()
```

This helped identify:

- Chrome app-mode windows were present in the raw filter and visible list.
- They were rejected only because their titles were empty.
- Filter state can change on focus/move/space events.
- Linear (and likely other Electron apps) never produce filter events at all,
  even when their windows are visible — which is why we no longer use the
  filter as a gatekeeper.

## User Data Collection Protocol

Be respectful of the user's context switching:

1. Patch temporary instrumentation.
2. Reload Hammerspoon yourself.
3. Verify helpers work through the bundled CLI.
4. Clear the log yourself.
5. Capture a baseline dump yourself.
6. Only then ask the user for one short reproduction pass.

Suggested request:

> The new logging is active. Please put the windows in the layout where the bug
> happens, press the right shortcut 8-12 times at a normal pace, then reply
> `done` with one sentence like "right looped between Chrome and Cursor" or
> "Calendar was skipped".

After the user replies, pull logs directly:

```bash
wc -l ~/.hammerspoon/window-switcher-debug.log
tail -n 40 ~/.hammerspoon/window-switcher-debug.log
rg -n 'switch-attempt|switch-loop-suspect|focused-missing|Niteshift|Calendar|Chrome|Finder|empty-title|0,"w":0|non-standard' ~/.hammerspoon/window-switcher-debug.log
```

Do not ask the user to paste logs unless file logging failed.

## Interpreting Logs

Common diagnoses:

- `visibleWindows` has the window but `finalWindows` does not: `is_focus_candidate`
  is rejecting it. Inspect `title`, `bundleID`, `role`, `subrole`, `isStandard`,
  `frame.area`, and `isMinimized`.
- `visibleWindows` does not have the window at all: Hammerspoon does not see
  it. Check accessibility permissions, check whether the window is on the
  current Space, and try `hs.application.find(<bundleID>):allWindows()` to
  confirm the window object exists at all.
- `rawWindows` (diagnostic filter) is missing a window that `visibleWindows`
  has: this is the `hs.window.filter` Electron gap. Expected, and is why
  production no longer uses the filter. Do not "fix" this by adding the window
  back to a filter allowlist; it will keep happening for the next Electron app.
- `rawWindows` has a bad `0x0` object that `visibleWindows` does not: stale
  filter object. Not a problem in production now that we do not gate on the
  filter, but worth knowing if you reintroduce one.
- `finalWindows` contains the target, but `switch-after-150ms` focused a
  different window: focus request did not land where expected. Look for app
  activation behavior, Finder desktop focus behavior, or macOS timing.
- `switch-focused-window-not-in-candidates`: focused window is not in the active
  list, so the code falls back to the first candidate. This often explains jumps.
- `loopSuspect=true`: same-direction keypress alternated between previous before
  and target windows. Compare candidate orders between the two attempts.
- Chrome app-mode windows with `title=""` are not automatically junk. Check
  bundle id before rejecting empty-title windows.
- Hammerspoon Console as a candidate is usually debug-induced noise.

## Cleanup Checklist

Before finishing:

- Remove verbose `append_debug`, `wsClearLog`, `wsStep`, event subscriptions,
  and timer-based per-switch logging unless the user explicitly wants to keep
  them.
- Keep only lightweight helpers that are safe during normal use, such as
  `wsDump()`.
- Delete stale logs:

```bash
rm -f ~/.hammerspoon/window-switcher-debug.log
```

- Reload Hammerspoon:

```bash
open -g hammerspoon://reload
```

- Verify the final active list:

```bash
"/Applications/Hammerspoon.app/Contents/Frameworks/hs/hs" -c 'return wsDump()'
```

## Bugs Fixed

Append new entries here when you fix something. Keep old entries; they make
regressions easier to spot.

1. Stale filter object (April 2026):
   - `hs.window.filter` could return an object with the same id as a real iTerm2
     window but empty title, blank role, and `0x0` frame.
   - Fix at the time: build final candidates from live
     `hs.window.visibleWindows()` and gate them by ids present in
     `switcher:getWindows()`.
   - Superseded by fix #3 below — the filter gate was removed entirely.
     `is_focus_candidate` still catches the stale 0×0 case via its `isStandard`
     and `frame.area > 0` checks.

2. Chrome app-mode empty titles (April 2026):
   - Niteshift and Google Calendar Chrome apps were valid standard windows but
     exposed `title=""`.
   - Fix: allow empty titles only for `com.google.Chrome.app.*` bundle ids with
     a real app name and nonzero standard window. Still in effect.

3. Linear / Electron app silently dropped (April 2026):
   - `hs.window.filter` did not track Linear (`com.linear`) at all — the window
     was visible, standard, with a real title and frame, but never appeared in
     `switcher:getWindows()`. The filter-membership intersection from fix #1
     then dropped Linear from the switcher.
   - Root cause: `hs.window.filter` relies on per-app AX subscriptions that
     some Electron apps do not produce.
   - Fix: removed the filter entirely. `ordered_windows()` now iterates
     `hs.window.visibleWindows()` and runs each window through
     `is_focus_candidate`. Verified empirically that `visibleWindows()` returns
     only current-Space windows on this machine, so the filter's
     `currentSpace = true` was the only behavior we lost — and we did not need
     it.
