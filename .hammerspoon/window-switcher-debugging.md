# Hammerspoon Directional Window Switcher Debugging

This runbook is for debugging `.hammerspoon/init.lua`, the directional window
switcher bound to `F16` and `Shift+F16`.

The goal for a future agent: drive the experiment yourself. Add temporary logs,
reload Hammerspoon automatically, verify that logging is live, then ask the user
for one focused reproduction pass. Do not make the user paste console logs unless
Hammerspoon fails before file logging starts.

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

The switcher uses a two-stage candidate model:

1. `hs.window.filter` provides broad membership:
   - visible windows
   - current Space
   - rejected junk titles like `Find in page` and `MenuBarCover`
2. `hs.window.visibleWindows()` provides the final live `hs.window` objects.

The final live-window step matters. `hs.window.filter` can hold stale objects:
we observed an `iTerm2` object with the same window id as the real terminal
window, but with an empty title, blank role, and a `0x0` frame. Using live
visible windows gated by filter membership avoided that stale object taking a
switching slot.

Expected final candidate rules:

- not minimized
- standard AX window
- nonzero frame area
- not Hammerspoon itself
- title not blacklisted
- empty title is rejected unless the bundle id starts with
  `com.google.Chrome.app.`
- Chrome app-mode windows with empty titles are allowed if they have a real app
  name and a standard nonzero window

Known Chrome app behavior:

- Chrome app windows can be valid focusable windows while reporting `title=""`.
- Examples observed:
  - `Niteshift`: `com.google.Chrome.app.ncgboinjakipfpjhkgpeoibgpgkedjba`
  - `Google Calendar`: `com.google.Chrome.app.kjbdgfilnfhdoflbpgamdcdgpehopbep`

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
probably focus behavior or changing candidate order, not filtering.

If `wsDump()` does not show the skipped window, add the temporary logging below
and compare raw filter, live visible windows, and final candidates.

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

When debugging filter problems, log three lists:

- raw filter list: `switcher:getWindows()`
- live visible list: `hs.window.visibleWindows()`
- final active list: `ordered_windows()`

Add or adapt helpers like these inside `init.lua`, where they can access local
functions such as `switcher`, `ordered_windows`, `sort_windows`, `window_id`,
`app_info`, `frame_info`, and `is_focus_candidate`:

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

local function debug_snapshot(label)
  local raw = sort_windows(switcher:getWindows())
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

For candidate-set churn, temporarily subscribe to window filter events. This can
produce lots of logs, so use it only during a short experiment.

```lua
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

  switcher:subscribe(events, function(win, app_name, event)
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

- `rawWindows` has a window, `visibleWindows` has it, but `finalWindows` does
  not: final candidate predicate is rejecting it. Inspect `title`, `bundleID`,
  `role`, `subrole`, `isStandard`, `frame.area`, and `isMinimized`.
- `rawWindows` has a bad `0x0` object, but `visibleWindows` has the real window:
  stale filter object. Prefer live visible window objects gated by raw filter ids.
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

## What Was Fixed In April 2026

Two concrete bugs were found:

1. Stale filter object:
   - `hs.window.filter` could return an object with the same id as a real iTerm2
     window but empty title, blank role, and `0x0` frame.
   - Fix: build final candidates from live `hs.window.visibleWindows()` and gate
     them by ids present in `switcher:getWindows()`.

2. Chrome app-mode empty titles:
   - Niteshift and Google Calendar Chrome apps were valid standard windows but
     exposed `title=""`.
   - Fix: allow empty titles only for `com.google.Chrome.app.*` bundle ids with
     a real app name and nonzero standard window.

The final config should keep both fixes.
