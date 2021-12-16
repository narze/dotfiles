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

-- Focus windows
local focusMods = {"alt"}

hs.hotkey.bind(focusMods, "e", function()
  hs.window.frontmostWindow().focusWindowNorth(nil, false, true)
  local rect = hs.window.frontmostWindow():frame()
  local center = hs.geometry.rectMidPoint(rect)
  hs.mouse.setAbsolutePosition(center)
end)

hs.hotkey.bind(focusMods, "i", function()
  hs.window.frontmostWindow().focusWindowEast(nil, false, true)
  local rect = hs.window.frontmostWindow():frame()
  local center = hs.geometry.rectMidPoint(rect)
  hs.mouse.setAbsolutePosition(center)
end)

hs.hotkey.bind(focusMods, "n", function()
  hs.window.frontmostWindow().focusWindowSouth(nil, false, true)
  local rect = hs.window.frontmostWindow():frame()
  local center = hs.geometry.rectMidPoint(rect)
  hs.mouse.setAbsolutePosition(center)
end)

hs.hotkey.bind(focusMods, "m", function()
  hs.window.frontmostWindow().focusWindowWest(nil, false, true)
  local rect = hs.window.frontmostWindow():frame()
  local center = hs.geometry.rectMidPoint(rect)
  hs.mouse.setAbsolutePosition(center)
end)
