-- Reload this config from the command line:
--   open -g hammerspoon://reload           # works anytime, uses the urlevent handler below
--   hs -c "hs.reload()"                    # requires the `hs` CLI (Preferences → Advanced → Install Command Line Tool)
-- Editing any *.lua under ~/.hammerspoon/ also auto-reloads via the pathwatcher below.

-- Directional window focus switcher.
-- Ported from .slate.js: sorts visible windows by center X across all apps/monitors,
-- steps to the next/previous window in that flat global order.
-- Bound to F16 (right) and Shift+F16 (left). No wrap at list boundaries.

local BLACKLIST_PREFIXES = {
  "Find in page",
  "MenuBarCover",
}

local function has_blacklisted_prefix(title)
  for _, prefix in ipairs(BLACKLIST_PREFIXES) do
    if title:sub(1, #prefix) == prefix then
      return true
    end
  end
  return false
end

local function is_valid(win)
  if not win then return false end
  if win:isMinimized() then return false end
  local title = win:title() or ""
  if title == "" then return false end
  if has_blacklisted_prefix(title) then return false end
  return true
end

local function center_x(win)
  local f = win:frame()
  return f.x + f.w / 2
end

local function ordered_windows()
  local wins = {}
  for _, win in ipairs(hs.window.visibleWindows()) do
    if is_valid(win) then
      table.insert(wins, win)
    end
  end
  table.sort(wins, function(a, b)
    local ca, cb = center_x(a), center_x(b)
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
  if not current or not is_valid(current) then
    wins[1]:focus()
    return
  end

  local idx
  for i, win in ipairs(wins) do
    if win:id() == current:id() then idx = i; break end
  end
  if not idx then wins[1]:focus(); return end

  local next_idx = direction == "right" and idx + 1 or idx - 1
  if next_idx >= 1 and next_idx <= #wins then
    wins[next_idx]:focus()
  end
end

hs.hotkey.bind({}, "f16", function() focus_step("right") end)
hs.hotkey.bind({"shift"}, "f16", function() focus_step("left") end)

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
