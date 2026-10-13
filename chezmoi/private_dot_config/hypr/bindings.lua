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

-- Lid close keeps the system running (logind HandleLidSwitch=ignore in
-- /etc/systemd/logind.conf.d/lid-no-suspend.conf), so turn the laptop panel off here.
-- ~/bin/lid-battery-suspend still suspends on battery below 20%.
hl.unbind("switch:on:Lid Switch")
o.bind("switch:on:Lid Switch", nil, [[omarchy-system-lid-close; hyprctl dispatch "hl.dsp.dpms({ action = \"disable\", monitor = \"$(omarchy-hyprland-monitor-laptop)\" })"; $HOME/bin/lid-battery-suspend]], { locked = true })
hl.unbind("switch:off:Lid Switch")
o.bind("switch:off:Lid Switch", nil, [[hyprctl dispatch "hl.dsp.dpms({ action = \"enable\", monitor = \"$(omarchy-hyprland-monitor-laptop)\" })"; omarchy-hyprland-monitor-clamshell]], { locked = true })
