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

require "wm"
