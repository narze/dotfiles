-- WindowHalfsAndThirds Spoon
hs.loadSpoon("WindowHalfsAndThirds")
-- spoon.WindowHalfsAndThirds:bindHotkeys(spoon.WindowHalfsAndThirds.defaultHotkeys)
spoon.WindowHalfsAndThirds:bindHotkeys({
  left_half   = { {"ctrl", "alt", "cmd"}, "m" },
  right_half  = { {"ctrl", "alt", "cmd"}, "i" },
  top_half    = { {"ctrl", "alt", "cmd"}, "e" },
  bottom_half = { {"ctrl", "alt", "cmd"}, "n" },
  third_left  = { {"ctrl", "alt"       }, "m" },
  third_right = { {"ctrl", "alt"       }, "i" },
  third_up    = { {"ctrl", "alt"       }, "e" },
  third_down  = { {"ctrl", "alt"       }, "n" },
  top_left    = { {"ctrl",        "cmd"}, "m" },
  top_right   = { {"ctrl",        "cmd"}, "n" },
  bottom_left = { {"ctrl",        "cmd"}, "e" },
  bottom_right= { {"ctrl",        "cmd"}, "i" },
  max_toggle  = { {"ctrl", "alt", "cmd"}, "t" },
  max         = { {"ctrl", "alt", "cmd"}, "Up" },
  undo        = { {        "alt", "cmd"}, "z" },
  center      = { {"ctrl", "alt", "cmd"}, "c" },
  larger      = { {"ctrl", "alt", "cmd"}, "y" },
  smaller     = { {"ctrl", "alt", "cmd"}, "u" },
})

-- Top-Left 1440p (2/3 of 2160p)
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "p", function()
  local win = hs.window.focusedWindow()
  if not win then return end

  local screen = win:screen()
  local res = screen:frame()
  local w = res.w * 2 / 3
  local h = res.h * 2 / 3

  win:move({x=0, y=0, w=w, h=h})
end)

-- Center
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "f", function()
  local win = hs.window.focusedWindow()
  if not win then return end

  local screen = win:screen()
  local res = screen:frame()
  local w = res.w * 2 / 3
  local h = res.h * 2 / 3
  local x = res.w * 1 / 6
  local y = res.h * 1 / 6

  win:move({x=x, y=y, w=w, h=h})
end)

-- Focus windows (migrated back to Yabai)
local focusMods = {"alt"}

hs.hotkey.bind(focusMods, "e", function()
  local current = hs.window.focusedWindow()
  local otherWindows = current:otherWindowsSameScreen()
  current:focusWindowNorth(otherWindows, true, true)

  local rect = hs.window.frontmostWindow():frame()
  local center = hs.geometry.rectMidPoint(rect)
  hs.mouse.absolutePosition(center)
end)

hs.hotkey.bind(focusMods, "i", function()
  local current = hs.window.focusedWindow()
  local otherWindows = current:otherWindowsSameScreen()
  current:focusWindowEast(otherWindows, true, true)

  local rect = hs.window.frontmostWindow():frame()
  local center = hs.geometry.rectMidPoint(rect)
  hs.mouse.absolutePosition(center)
end)

hs.hotkey.bind(focusMods, "n", function()
  local current = hs.window.focusedWindow()
  local otherWindows = current:otherWindowsSameScreen()
  current:focusWindowSouth(otherWindows, true, true)

  local rect = hs.window.frontmostWindow():frame()
  local center = hs.geometry.rectMidPoint(rect)
  hs.mouse.absolutePosition(center)
end)

hs.hotkey.bind(focusMods, "m", function()
  local current = hs.window.focusedWindow()
  local otherWindows = current:otherWindowsSameScreen()
  current:focusWindowWest(otherWindows, true, true)

  local rect = hs.window.frontmostWindow():frame()
  local center = hs.geometry.rectMidPoint(rect)
  hs.mouse.absolutePosition(center)
end)

-- Move Windows to Screen
local moveMods = {"alt", "shift"}

hs.hotkey.bind(moveMods, "u", function()
  local win = hs.window.focusedWindow()
  if not win then return end
  win:moveOneScreenWest(nil, nil, 0.3)
end)

hs.hotkey.bind(moveMods, "y", function()
  local win = hs.window.focusedWindow()
  if not win then return end
  win:moveOneScreenEast(nil, nil, 0.3)
end)

function getIndexFromValue(tbl, value)
  for index, val in ipairs(tbl) do
      if val == value then
          return index
      end
  end
  return nil  -- return nil if the value is not found
end

-- Spaces
-- Go to next space (increment)
hs.hotkey.bind({"alt"}, ";", function()
  local currentSpace = hs.spaces.focusedSpace()
  local currentScreen = hs.spaces.spaceDisplay(currentSpace)

  local spacesInScreen = hs.spaces.spacesForScreen(currentScreen)
  local currentScreenIndex = getIndexFromValue(spacesInScreen, currentSpace)

  local nextSpace = spacesInScreen[currentScreenIndex + 1]

  if not nextSpace then
    print("No next space")
    return
  end

  hs.spaces.gotoSpace(nextSpace)
end)

-- Go to previous space (decrement)
hs.hotkey.bind({"alt"}, "l", function()
  local currentSpace = hs.spaces.focusedSpace()
  local currentScreen = hs.spaces.spaceDisplay(currentSpace)

  local spacesInScreen = hs.spaces.spacesForScreen(currentScreen)
  local currentScreenIndex = getIndexFromValue(spacesInScreen, currentSpace)
  local prevSpace = spacesInScreen[currentScreenIndex - 1]

  -- return if null
  if not prevSpace then
    print("No previous space")
    return
  end

  hs.spaces.gotoSpace(prevSpace)
end)

-- Monitors
---
-- A reusable function to focus the most recent window on an adjacent screen.
-- @param direction A string, either "next" or "previous".
---
local function focusWindowOnAdjacentScreen(direction)
  -- 1. Get the screen where the currently focused window is located
  local currentWindow = hs.window.focusedWindow()
  if not currentWindow then
    print("No window focused")
    return
  end
  local currentScreen = currentWindow:screen()

  -- 2. If there's only one screen, there's nowhere to go
  if #hs.screen.allScreens() <= 1 then
    print("Only one display connected")
    return
  end

  -- 3. Find the target screen based on the direction parameter
  local targetScreen
  if direction == "next" then
    targetScreen = currentScreen:next()
  elseif direction == "previous" then
    targetScreen = currentScreen:previous()
  else
    -- This is for safety, in case we call the function with a wrong parameter
    print("Error: Invalid direction")
    return
  end

  -- 4. Find the most recently used window on that target screen
  local targetWindow = nil
  for _, win in ipairs(hs.window.orderedWindows()) do
    -- Check if the window is a standard window and on the target screen
    if win:screen() and win:screen():id() == targetScreen:id() and win:isStandard() then
      targetWindow = win
      break -- Stop at the first one (the most recent)
    end
  end

  -- 5. If we found a suitable window, focus it
  if targetWindow then
    targetWindow:focus()

    local rect = targetWindow:frame()
    local center = hs.geometry.rectMidPoint(rect)

    hs.mouse.absolutePosition(center)
  else
    print("No windows on " .. direction .. " display")
  end
end

-- =============================================================================
-- Hotkey Bindings
-- =============================================================================

hs.hotkey.bind({"alt"}, "y", function()
  focusWindowOnAdjacentScreen("next")
end)

hs.hotkey.bind({"alt"}, "u", function()
  focusWindowOnAdjacentScreen("previous")
end)

-- Hide current application with alt-h
hs.hotkey.bind({"alt"}, "h", function()
  local win = hs.window.focusedWindow()
  local app = win:application()
  app:hide()
end)
