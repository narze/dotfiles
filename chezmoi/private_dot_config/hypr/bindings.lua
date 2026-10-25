-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Universal paste on physical V (code:55) too. Colemak-DH puts "v" on physical B,
-- but macOS muscle memory (also through Moonlight) pastes with Cmd + physical V.
-- Same logic as /usr/share/omarchy/default/hypr/bindings/clipboard.lua, whose
-- helpers are local to that file.
local function send_shortcut_once(mods, key)
  hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
  hl.timer(function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
  end, { timeout = 50, type = "oneshot" })
end

local function active_window_is_terminal()
  local window = hl.get_active_window()
  for _, tag in ipairs(window and window.tags or {}) do
    if tag:gsub("%*$", "") == "terminal" then
      return true
    end
  end
  return false
end

o.bind("SUPER + code:55", "Universal paste (physical V)", function()
  if active_window_is_terminal() then
    send_shortcut_once("SHIFT", "Insert")
  else
    send_shortcut_once("CTRL", "V")
  end
end)

-- Lid close keeps the system running (logind HandleLidSwitch=ignore in
-- /etc/systemd/logind.conf.d/lid-no-suspend.conf), so turn the laptop panel off here.
-- ~/bin/lid-battery-suspend still suspends on battery below 20%.
hl.unbind("switch:on:Lid Switch")
o.bind("switch:on:Lid Switch", nil, [[omarchy-system-lid-close; hyprctl dispatch "hl.dsp.dpms({ action = \"disable\", monitor = \"$(omarchy-hyprland-monitor-laptop)\" })"; $HOME/bin/lid-battery-suspend]], { locked = true })
hl.unbind("switch:off:Lid Switch")
o.bind("switch:off:Lid Switch", nil, [[hyprctl dispatch "hl.dsp.dpms({ action = \"enable\", monitor = \"$(omarchy-hyprland-monitor-laptop)\" })"; omarchy-hyprland-monitor-clamshell]], { locked = true })

-- macOS OmniWM/yabai-style WM keys. ALT is the Mac Option position because kanata
-- swaps the physical Win and Alt keys. Focus uses the Colemak-DH home row
-- (m/n/e/i = left/down/up/right), the same letters as yabai's skhdrc.
-- Super + arrows (Omarchy default) stay as a fallback.
o.bind("ALT + M", "Focus on left window", hl.dsp.focus({ direction = "l" }))
o.bind("ALT + N", "Focus on below window", hl.dsp.focus({ direction = "d" }))
o.bind("ALT + E", "Focus on above window", hl.dsp.focus({ direction = "u" }))
o.bind("ALT + I", "Focus on right window", hl.dsp.focus({ direction = "r" }))

-- Swap windows in place (yabai: alt+shift+m/n/e/i).
o.bind("ALT + SHIFT + M", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
o.bind("ALT + SHIFT + N", "Swap window down", hl.dsp.window.swap({ direction = "d" }))
o.bind("ALT + SHIFT + E", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("ALT + SHIFT + I", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))

-- Send the window to a workspace and stay on the current one (yabai: shift+alt+1..8).
for workspace = 1, 8 do
  o.bind("ALT + SHIFT + code:" .. (workspace + 9), "Move window to workspace " .. workspace,
    hl.dsp.window.move({ workspace = tostring(workspace), follow = false }))
end

-- Switch workspace on ALT + 1..8 (yabai: alt+1..8) instead of Omarchy's SUPER + 1..8.
-- SUPER + 9 and SUPER + 0 stay as the Omarchy defaults. Omarchy binds the digit row
-- by physical keycode (code:10 is "1"), so unbind and bind the same way.
for workspace = 1, 8 do
  local key = "code:" .. (workspace + 9)
  hl.unbind("SUPER + " .. key)
  o.bind("ALT + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
end

-- Previous/next workspace (yabai: alt+l and alt+0x23, the physical P key).
o.bind("ALT + L", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
-- Kanata swaps ; and : on that key and adds Shift, so plain Alt + P arrives as
-- ALT + SHIFT + colon. Bind the keycode (33) so the keysym does not matter.
o.bind("ALT + SHIFT + code:33", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))

-- Focus the monitor to the left/right (yabai: alt+u west, alt+y east).
o.bind("ALT + U", "Focus on left monitor", hl.dsp.focus({ monitor = "l" }))
o.bind("ALT + Y", "Focus on right monitor", hl.dsp.focus({ monitor = "r" }))

-- SUPER + W sends CTRL + W to every app, like Cmd + W on macOS: it closes a tab or
-- document, and a browser window only closes with its last tab. This includes
-- terminals, where CTRL + W goes to the shell. ALT + W closes the window itself
-- (yabai: alt+w).
hl.unbind("SUPER + W")
o.bind("SUPER + W", "Universal close (CTRL+W)", function()
  send_shortcut_once("CTRL", "W")
end)
o.bind("ALT + W", "Close window", hl.dsp.window.close())

-- hyprshell owns SUPER + TAB (hold Super, tap Tab to switch windows like macOS Cmd+Tab),
-- so drop Omarchy's next/previous workspace binds on the same keys. Workspaces move
-- on ALT + L and ALT + SEMICOLON instead.
hl.unbind("SUPER + TAB")
hl.unbind("SUPER + SHIFT + TAB")

-- Send the window to the previous/next workspace and stay (yabai: alt+shift+l and
-- alt+shift+0x23). Kanata turns Shift + P into plain P, so "next" is ALT + code:33.
o.bind("ALT + SHIFT + L", "Move window to previous workspace", hl.dsp.window.move({ workspace = "e-1", follow = false }))
o.bind("ALT + code:33", "Move window to next workspace", hl.dsp.window.move({ workspace = "e+1", follow = false }))

-- Move the window to the monitor on the left/right and follow it (yabai: alt+shift+u/y).
o.bind("ALT + SHIFT + U", "Move window to left monitor", hl.dsp.window.move({ monitor = "l" }))
o.bind("ALT + SHIFT + Y", "Move window to right monitor", hl.dsp.window.move({ monitor = "r" }))

-- CTRL + SPACE opens the launcher (Omarchy's SUPER + SPACE did this). SUPER + SPACE
-- toggles the keyboard layout instead (English/Thai), like the macOS input source key.
o.bind("CTRL + SPACE", "Omarchy menu", "omarchy-menu toggle")
hl.unbind("SUPER + SPACE")
o.bind("SUPER + SPACE", "Toggle keyboard layout", "hyprctl switchxkblayout all next")

-- Window state keys moved from SUPER to ALT, like yabai/OmniWM. The old Omarchy SUPER
-- binds are removed. Same actions as default/hypr/bindings/tiling.lua. The "a little"
-- and "a lot" resize variants stay on SUPER.
hl.unbind("SUPER + F")
hl.unbind("SUPER + CTRL + F")
hl.unbind("SUPER + T")
hl.unbind("SUPER + J")
hl.unbind("SUPER + L")
hl.unbind("SUPER + S")
hl.unbind("SUPER + ALT + S")
hl.unbind("SUPER + code:20")
hl.unbind("SUPER + code:21")
hl.unbind("SUPER + SHIFT + code:20")
hl.unbind("SUPER + SHIFT + code:21")

o.bind("ALT + F", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
o.bind("ALT + Z", "Tiled full screen", "omarchy-hyprland-window-tiled-fullscreen-toggle")
o.bind("ALT + T", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))
o.bind("ALT + C", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("ALT + R", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")
o.bind("ALT + S", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
o.bind("ALT + SHIFT + S", "Move window to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

-- Resize with ALT + minus/equal (code:20 and code:21), Shift for the vertical edge.
o.bind("ALT + code:20", "Expand window left", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
o.bind("ALT + code:21", "Shrink window left", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
o.bind("ALT + SHIFT + code:20", "Shrink window up", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
o.bind("ALT + SHIFT + code:21", "Expand window down", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))
