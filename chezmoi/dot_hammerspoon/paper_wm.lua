PaperWM = hs.loadSpoon("PaperWM")

PaperWM:bindHotkeys({
    -- switch to a new focused window in tiled grid
    focus_left  = {{"alt"}, "m"},
    focus_right = {{"alt"}, "i"},
    focus_up    = {{"alt"}, "e"},
    focus_down  = {{"alt"}, "n"},

    -- switch windows by cycling forward/backward
    -- (forward = down or right, backward = up or left)
    focus_prev = {{"alt"}, ","},
    focus_next = {{"alt"}, "."},

    -- move windows around in tiled grid
    swap_left  = {{"alt", "shift"}, "m"},
    swap_right = {{"alt", "shift"}, "i"},
    swap_up    = {{"alt", "shift"}, "e"},
    swap_down  = {{"alt", "shift"}, "n"},

    -- alternative: swap entire columns, rather than
    -- individual windows (to be used instead of
    -- swap_left / swap_right bindings)
    -- swap_column_left = {{"alt", "cmd", "shift"}, "left"},
    -- swap_column_right = {{"alt", "cmd", "shift"}, "right"},

    -- position and resize focused window
    center_window        = {{"alt"}, "t"},
    full_width           = {{"alt"}, "z"},
    cycle_width          = {{"alt"}, "r"},
    reverse_cycle_width  = {{"ctrl", "alt"}, "r"},
    cycle_height         = {{"alt", "cmd", "shift"}, "r"},
    reverse_cycle_height = {{"ctrl", "alt", "cmd", "shift"}, "r"},

    -- increase/decrease width
    increase_width = {{"alt", "cmd"}, "t"},
    decrease_width = {{"alt", "cmd"}, "s"},

    -- move focused window into / out of a column-
    slurp_in = {{"alt", "cmd"}, "i"},
    barf_out = {{"alt", "cmd"}, "o"},

    -- move the focused window into / out of the tiling layer
    toggle_floating = {{"alt"}, "f"},

    -- focus the first / second / etc window in the current space
    focus_window_1 = {{"cmd", "alt"}, "1"},
    focus_window_2 = {{"cmd", "alt"}, "2"},
    focus_window_3 = {{"cmd", "alt"}, "3"},
    focus_window_4 = {{"cmd", "alt"}, "4"},
    focus_window_5 = {{"cmd", "alt"}, "5"},
    focus_window_6 = {{"cmd", "alt"}, "6"},
    focus_window_7 = {{"cmd", "alt"}, "7"},
    focus_window_8 = {{"cmd", "alt"}, "8"},
    focus_window_9 = {{"cmd", "alt"}, "9"},

    -- switch to a new Mission Control space
    switch_space_l = {{"alt", "cmd"}, "l"},
    switch_space_r = {{"alt", "cmd"}, ";"},
    switch_space_1 = {{"alt"}, "1"},
    switch_space_2 = {{"alt"}, "2"},
    switch_space_3 = {{"alt"}, "3"},
    switch_space_4 = {{"alt"}, "4"},
    switch_space_5 = {{"alt"}, "5"},
    switch_space_6 = {{"alt"}, "6"},
    switch_space_7 = {{"alt"}, "7"},
    switch_space_8 = {{"alt"}, "8"},
    switch_space_9 = {{"alt"}, "9"},

    -- move focused window to a new space and tile
    move_window_1 = {{"alt", "shift"}, "1"},
    move_window_2 = {{"alt", "shift"}, "2"},
    move_window_3 = {{"alt", "shift"}, "3"},
    move_window_4 = {{"alt", "shift"}, "4"},
    move_window_5 = {{"alt", "shift"}, "5"},
    move_window_6 = {{"alt", "shift"}, "6"},
    move_window_7 = {{"alt", "shift"}, "7"},
    move_window_8 = {{"alt", "shift"}, "8"},
    move_window_9 = {{"alt", "shift"}, "9"}
})

-- Defaults
-- PaperWM:bindHotkeys({
--     -- switch to a new focused window in tiled grid
--     focus_left  = {{"alt", "cmd"}, "left"},
--     focus_right = {{"alt", "cmd"}, "right"},
--     focus_up    = {{"alt", "cmd"}, "up"},
--     focus_down  = {{"alt", "cmd"}, "down"},

--     -- switch windows by cycling forward/backward
--     -- (forward = down or right, backward = up or left)
--     focus_prev = {{"alt", "cmd"}, "k"},
--     focus_next = {{"alt", "cmd"}, "j"},

--     -- move windows around in tiled grid
--     swap_left  = {{"alt", "cmd", "shift"}, "left"},
--     swap_right = {{"alt", "cmd", "shift"}, "right"},
--     swap_up    = {{"alt", "cmd", "shift"}, "up"},
--     swap_down  = {{"alt", "cmd", "shift"}, "down"},

--     -- alternative: swap entire columns, rather than
--     -- individual windows (to be used instead of
--     -- swap_left / swap_right bindings)
--     -- swap_column_left = {{"alt", "cmd", "shift"}, "left"},
--     -- swap_column_right = {{"alt", "cmd", "shift"}, "right"},

--     -- position and resize focused window
--     center_window        = {{"alt", "cmd"}, "c"},
--     full_width           = {{"alt", "cmd"}, "f"},
--     cycle_width          = {{"alt", "cmd"}, "r"},
--     reverse_cycle_width  = {{"ctrl", "alt", "cmd"}, "r"},
--     cycle_height         = {{"alt", "cmd", "shift"}, "r"},
--     reverse_cycle_height = {{"ctrl", "alt", "cmd", "shift"}, "r"},

--     -- increase/decrease width
--     increase_width = {{"alt", "cmd"}, "l"},
--     decrease_width = {{"alt", "cmd"}, "h"},

--     -- move focused window into / out of a column-
--     slurp_in = {{"alt", "cmd"}, "i"},
--     barf_out = {{"alt", "cmd"}, "o"},

--     -- move the focused window into / out of the tiling layer
--     toggle_floating = {{"alt", "cmd", "shift"}, "escape"},

--     -- focus the first / second / etc window in the current space
--     focus_window_1 = {{"cmd", "shift"}, "1"},
--     focus_window_2 = {{"cmd", "shift"}, "2"},
--     focus_window_3 = {{"cmd", "shift"}, "3"},
--     focus_window_4 = {{"cmd", "shift"}, "4"},
--     focus_window_5 = {{"cmd", "shift"}, "5"},
--     focus_window_6 = {{"cmd", "shift"}, "6"},
--     focus_window_7 = {{"cmd", "shift"}, "7"},
--     focus_window_8 = {{"cmd", "shift"}, "8"},
--     focus_window_9 = {{"cmd", "shift"}, "9"},

--     -- switch to a new Mission Control space
--     switch_space_l = {{"alt", "cmd"}, ","},
--     switch_space_r = {{"alt", "cmd"}, "."},
--     switch_space_1 = {{"alt", "cmd"}, "1"},
--     switch_space_2 = {{"alt", "cmd"}, "2"},
--     switch_space_3 = {{"alt", "cmd"}, "3"},
--     switch_space_4 = {{"alt", "cmd"}, "4"},
--     switch_space_5 = {{"alt", "cmd"}, "5"},
--     switch_space_6 = {{"alt", "cmd"}, "6"},
--     switch_space_7 = {{"alt", "cmd"}, "7"},
--     switch_space_8 = {{"alt", "cmd"}, "8"},
--     switch_space_9 = {{"alt", "cmd"}, "9"},

--     -- move focused window to a new space and tile
--     move_window_1 = {{"alt", "cmd", "shift"}, "1"},
--     move_window_2 = {{"alt", "cmd", "shift"}, "2"},
--     move_window_3 = {{"alt", "cmd", "shift"}, "3"},
--     move_window_4 = {{"alt", "cmd", "shift"}, "4"},
--     move_window_5 = {{"alt", "cmd", "shift"}, "5"},
--     move_window_6 = {{"alt", "cmd", "shift"}, "6"},
--     move_window_7 = {{"alt", "cmd", "shift"}, "7"},
--     move_window_8 = {{"alt", "cmd", "shift"}, "8"},
--     move_window_9 = {{"alt", "cmd", "shift"}, "9"}
-- })

PaperWM:start()
