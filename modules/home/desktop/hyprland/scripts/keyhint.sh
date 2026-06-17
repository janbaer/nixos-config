#!/usr/bin/env bash

yad --width=560 --height=720 \
--center \
--fixed \
--title="Hyprland Keybindings" \
--no-buttons \
--list \
--column=Key: \
--column=Action: \
--column=Notes: \
--timeout=60 \
--timeout-indicator=right \
"+Enter" "Terminal" "Ghostty" \
"+Shift+Enter" "File manager" "Nautilus" \
"+b" "Browser" "Firefox" \
"+d" "App launcher" "Noctalia (drun)" \
"+Space" "Run command" "Noctalia" \
"+Shift+p" "Clipboard history" "Noctalia" \
"+f" "Fullscreen" "Toggle" \
"+v" "Toggle floating" "" \
"+p" "Pseudo tile" "dwindle" \
"+j" "Toggle split" "dwindle" \
"+Shift+q" "Close window" "Kill active" \
"+Arrows" "Move focus" "Left / Down / Up / Right" \
"+Shift+Arrows" "Move window" "Left / Down / Up / Right" \
"+LMB drag" "Move window" "" \
"+Shift+LMB drag" "Resize window" "" \
"Alt+r" "Resize mode" "Arrows resize, Esc exits" \
"+1 .. 0" "Switch workspace" "1 to 10" \
"+Shift+1 .. 0" "Send window to workspace" "1 to 10" \
"+Home / End" "First / last workspace" "1 / 10" \
"+Alt+Left/Right" "Prev / next workspace" "Relative" \
"+Scroll" "Cycle workspaces" "Mouse wheel" \
"+s  or  +-" "Scratchpad" "Toggle special workspace" \
"+Shift+-" "Send to scratchpad" "Special workspace" \
"+Shift+e" "Session menu" "Noctalia (logout/lock/reboot/off)" \
"+Shift+l" "Lock screen" "Noctalia / hyprlock" \
"+Shift+s" "Suspend" "systemctl suspend" \
"+Shift+y" "Screenshot region" "grim + slurp -> swappy" \
"+Shift+h" "This help" "Keybindings cheat sheet" \
"" "" "Closes in 60 s"
