# In your Hyprland module (e.g., modules/home/desktop/hyprland/default.nix)
{ config, lib, pkgs, ... }:

{
  # Create the window switcher script
  home.packages = with pkgs;
    [
      (writeShellScriptBin "hypr-window-switcher" ''
        #!/usr/bin/env bash

        # Get list of windows from hyprctl and format for rofi
        windows=$(${pkgs.hyprland}/bin/hyprctl clients -j | ${pkgs.jq}/bin/jq -r '.[] | select(.mapped == true) | "\(.address)|\(.class)|\(.title)"')

        # Create rofi menu entries
        menu_entries=""
        declare -A window_addresses

        while IFS='|' read -r address class title; do
          # Format the display text (limit title length)
          short_title=$(echo "$title" | cut -c1-50)
          display_text="$class: $short_title"
          menu_entries+="$display_text"$'\n'
          window_addresses["$display_text"]="$address"
        done <<< "$windows"

        # Show rofi menu and get selection
        selected=$(echo -e "$menu_entries" | ${pkgs.rofi}/bin/rofi -dmenu -p "Switch to window:" -i -theme-str 'window {width: 50%;}')

        # Focus the selected window
        if [ -n "$selected" ]; then
          address="''${window_addresses[$selected]}"
          if [ -n "$address" ]; then
            ${pkgs.hyprland}/bin/hyprctl dispatch focuswindow "address:$address"
          fi
        fi
      '')
    ];

  wayland.windowManager.hyprland = {
    settings = { bind = [ "SUPER, Tab, exec, hypr-window-switcher" ]; };
  };
}
