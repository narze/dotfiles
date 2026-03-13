-- stackline = require "stackline"
-- stackline = require "stackline.stackline.stackline"

-- local config = {
--     -- appearance = {
--     --   showIcons = false,       -- default is true
--     -- },
--     features = {
--         clickToFocus = false,  -- default is true
--         -- fzyFrameDetect = {
--         --     fuzzFactor = 25    -- default is 30
--         -- },
--     },
-- }

-- stackline:init(config)
-- stackline:init()

-- Disable since it messes with yabai focusing apps like OpenIn
-- hs.loadSpoon("FocusHighlight")
-- spoon.FocusHighlight:start()
-- spoon.FocusHighlight.color = "#ffffff"
-- spoon.FocusHighlight.windowFilter = hs.window.filter.default
-- spoon.FocusHighlight.arrowSize = 0
-- spoon.FocusHighlight.arrowFadeOutDuration = 0
-- spoon.FocusHighlight.highlightFadeOutDuration = 0.3
-- spoon.FocusHighlight.highlightFillAlpha = 0.03

-- require "wm"

-- require "paper_wm"

-- WarpMouse = hs.loadSpoon("WarpMouse")
-- WarpMouse.margin = 8  -- optionally set how far past a screen edge the mouse should warp, default is 2 pixels
-- WarpMouse:start()

-- MouseFollowsFocus = hs.loadSpoon("MouseFollowsFocus")
-- MouseFollowsFocus:start()

-- Function to be called from command line
function centerAndResizeWindow()
  local win = hs.window.focusedWindow()
  if not win then return end

  local screen = win:screen()
  local res = screen:frame()
  local w = res.w * 2 / 3
  local h = res.h * 2 / 3
  local x = res.w * 1 / 6
  local y = res.h * 1 / 6

  win:setFrame(hs.geometry.rect(x, y, w, h), 0)
end

hs.ipc.cliInstall()
