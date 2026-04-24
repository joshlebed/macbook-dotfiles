-- Reload this config from the command line:
--   open -g hammerspoon://reload           # works anytime, uses the urlevent handler below
--   hs -c "hs.reload()"                    # requires the `hs` CLI (Preferences → Advanced → Install Command Line Tool)
-- Editing any *.lua under ~/.hammerspoon/ also auto-reloads via the pathwatcher below.

-- Directional window focus.
-- Flat global ordering by window center-X: every window in the filter gets a
-- slot in the list, and F16 / Shift+F16 step one slot at a time. Unlike
-- hs.window.filter:focusWindowEast, windows occluded behind others at the same
-- X are not skipped — they're just a later step in the traversal.
--
-- The filter gives us a curated, event-driven window set (no per-keypress
-- scan of every app's windows, and junk titles are excluded upfront).
local switcher = hs.window.filter.new()
  :setDefaultFilter({})
  :setOverrideFilter({
    visible = true,
    currentSpace = true,
    rejectTitles = { "^Find in page", "^MenuBarCover" },
  })

local function ordered_windows()
  local wins = switcher:getWindows()
  table.sort(wins, function(a, b)
    local fa, fb = a:frame(), b:frame()
    local ca, cb = fa.x + fa.w / 2, fb.x + fb.w / 2
    if ca ~= cb then return ca < cb end
    local ta, tb = a:title() or "", b:title() or ""
    if ta ~= tb then return ta < tb end
    return (a:id() or 0) < (b:id() or 0)
  end)
  return wins
end

local function focus_step(direction)
  local wins = ordered_windows()
  if #wins == 0 then return end

  local current = hs.window.focusedWindow()
  if not current then wins[1]:focus(); return end

  local idx
  for i, w in ipairs(wins) do
    if w:id() == current:id() then idx = i; break end
  end
  if not idx then wins[1]:focus(); return end

  local next_idx = direction == "east" and idx + 1 or idx - 1
  if next_idx >= 1 and next_idx <= #wins then
    wins[next_idx]:focus()
  end
end

hs.hotkey.bind({},        "f16", function() focus_step("east") end)
hs.hotkey.bind({"shift"}, "f16", function() focus_step("west") end)

-- Enable `hs -c "hs.reload()"` from the shell. Idempotent.
hs.ipc.cliInstall()

-- Enable `open -g hammerspoon://reload` from the shell.
hs.urlevent.bind("reload", function() hs.reload() end)

-- Auto-reload when this file changes.
hs.pathwatcher.new(hs.configdir, function(paths)
  for _, p in ipairs(paths) do
    if p:match("%.lua$") then hs.reload(); return end
  end
end):start()

hs.alert.show("Hammerspoon config loaded")
