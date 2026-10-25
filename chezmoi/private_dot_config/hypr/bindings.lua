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
  o.bind("ALT + SHIFT + " .. workspace, "Move window to workspace " .. workspace,
    hl.dsp.window.move({ workspace = tostring(workspace), follow = false }))
end
