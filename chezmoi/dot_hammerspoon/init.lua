stackline = require "stackline"
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
stackline:init()

hs.loadSpoon("FocusHighlight")
spoon.FocusHighlight:start()
spoon.FocusHighlight.color = "#ffffff"
spoon.FocusHighlight.windowFilter = hs.window.filter.default
spoon.FocusHighlight.arrowSize = 0
spoon.FocusHighlight.arrowFadeOutDuration = 0
spoon.FocusHighlight.highlightFadeOutDuration = 0.3
spoon.FocusHighlight.highlightFillAlpha = 0.03

require "wm"
