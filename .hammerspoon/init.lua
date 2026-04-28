-- Reload this config from the command line:
--   open -g hammerspoon://reload           -- works anytime, uses the urlevent handler below
--   hs -c "hs.reload()"                    -- requires the `hs` CLI (Preferences -> Advanced -> Install Command Line Tool)
-- Editing any *.lua under ~/.hammerspoon/ also auto-reloads via the pathwatcher below.

-- Directional window focus.
-- Flat global ordering by window center-X: every window in the filter gets a
-- slot in the list, and F16 / Shift+F16 step one slot at a time. Unlike
-- hs.window.filter:focusWindowEast, windows occluded behind others at the same
-- X are not skipped -- they're just a later step in the traversal.
--
-- The filter decides broad membership/current Space. The final candidate list
-- is built from live hs.window.visibleWindows() objects so stale filter objects
-- with empty titles/frames cannot steal a slot.
local REJECT_TITLE_PATTERNS = {
  "^Find in page",
  "^MenuBarCover",
}

local switcher = hs.window.filter.new()
  :setDefaultFilter({})
  :setOverrideFilter({
    visible = true,
    currentSpace = true,
    rejectTitles = REJECT_TITLE_PATTERNS,
  })

local function safe_value(fallback, fn)
  local ok, value = pcall(fn)
  if ok and value ~= nil then return value end
  return fallback
end

local function app_info(win)
  local app = safe_value(nil, function() return win:application() end)
  if not app then return { name = "", bundleID = "" } end

  return {
    name = safe_value("", function() return app:name() end),
    bundleID = safe_value("", function() return app:bundleID() end),
  }
end

local function frame_info(win)
  local frame = safe_value(nil, function() return win:frame() end)
  if not frame then return { x = 0, y = 0, w = 0, h = 0, cx = 0, area = 0 } end

  return {
    x = frame.x,
    y = frame.y,
    w = frame.w,
    h = frame.h,
    cx = frame.x + frame.w / 2,
    area = frame.w * frame.h,
  }
end

local function window_title(win)
  return safe_value("", function() return win:title() or "" end)
end

local function has_rejected_title(title)
  for _, pattern in ipairs(REJECT_TITLE_PATTERNS) do
    if title:match(pattern) then return true end
  end
  return false
end

local function is_chrome_app_bundle(bundle_id)
  return type(bundle_id) == "string" and bundle_id:match("^com%.google%.Chrome%.app%.") ~= nil
end

local function window_id(win)
  return safe_value(nil, function() return win:id() end)
end

local function sortable_title(win)
  local title = window_title(win)
  if title ~= "" then return title end

  local app = app_info(win)
  if app.name ~= "" then return app.name end
  return app.bundleID
end

local function is_focus_candidate(win)
  if not win then return false end

  local app = app_info(win)
  if app.bundleID == "org.hammerspoon.Hammerspoon" then return false end

  if safe_value(true, function() return win:isMinimized() end) then return false end
  if safe_value(false, function() return win:isStandard() end) ~= true then return false end

  local frame = frame_info(win)
  if frame.area <= 0 then return false end

  local title = window_title(win)
  if has_rejected_title(title) then return false end

  -- Chrome app windows can be perfectly valid but expose an empty AX title.
  if title == "" and not is_chrome_app_bundle(app.bundleID) then return false end
  if title == "" and app.name == "" then return false end

  return true
end

local function sort_windows(wins)
  local sorted = {}
  for _, win in ipairs(wins or {}) do table.insert(sorted, win) end

  table.sort(sorted, function(a, b)
    local ca, cb = frame_info(a).cx, frame_info(b).cx
    if ca ~= cb then return ca < cb end

    local ta, tb = sortable_title(a), sortable_title(b)
    if ta ~= tb then return ta < tb end

    return (window_id(a) or 0) < (window_id(b) or 0)
  end)

  return sorted
end

local function window_id_set(wins)
  local ids = {}
  for _, win in ipairs(wins or {}) do
    local id = window_id(win)
    if id then ids[id] = true end
  end
  return ids
end

local function ordered_windows()
  local allowed_ids = window_id_set(switcher:getWindows())
  local wins = {}

  for _, win in ipairs(hs.window.visibleWindows()) do
    local id = window_id(win)
    if id and allowed_ids[id] and is_focus_candidate(win) then
      table.insert(wins, win)
    end
  end

  return sort_windows(wins)
end

local function describe_window(win)
  if not win then return nil end

  local app = app_info(win)
  local frame = frame_info(win)
  return {
    id = window_id(win),
    app = app.name,
    bundleID = app.bundleID,
    title = window_title(win),
    role = safe_value("", function() return win:role() end),
    subrole = safe_value("", function() return win:subrole() end),
    isStandard = safe_value(false, function() return win:isStandard() end),
    frame = frame,
    centerX = frame.cx,
    candidate = is_focus_candidate(win),
  }
end

local function focus_step(direction)
  local wins = ordered_windows()
  if #wins == 0 then return end

  local current = hs.window.focusedWindow()
  if not current then wins[1]:focus(); return end

  local idx
  local current_id = window_id(current)
  for i, win in ipairs(wins) do
    if window_id(win) == current_id then idx = i; break end
  end
  if not idx then wins[1]:focus(); return end

  local next_idx = direction == "east" and idx + 1 or idx - 1
  if next_idx >= 1 and next_idx <= #wins then
    wins[next_idx]:focus()
  end
end

hs.hotkey.bind({},        "f16", function() focus_step("east") end)
hs.hotkey.bind({"shift"}, "f16", function() focus_step("west") end)

-- Lightweight console helper for future inspection.
_G.wsDump = function()
  local wins = ordered_windows()
  local out = {}
  for index, win in ipairs(wins) do
    local desc = describe_window(win)
    desc.index = index
    table.insert(out, desc)
  end
  return hs.inspect(out)
end

-- Enable `hs -c "hs.reload()"` from the shell. Idempotent.
hs.ipc.cliInstall()

-- Enable `open -g hammerspoon://reload` from the shell.
hs.urlevent.bind("reload", function() hs.reload() end)

-- Auto-reload when this file changes.
_G.windowSwitcherConfigWatcher = hs.pathwatcher.new(hs.configdir, function(paths)
  for _, p in ipairs(paths) do
    if p:match("%.lua$") then hs.reload(); return end
  end
end):start()

hs.alert.show("Hammerspoon config loaded")
