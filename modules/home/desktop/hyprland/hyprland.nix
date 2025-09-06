{ config, lib, pkgs, hostname, ... }:
let
  inherit (import ./../../../../hosts/${hostname}/variables.nix)
    useHyprland extraMonitorSettings;
in {
  wayland.windowManager.hyprland = {
    enable = useHyprland;
    package = pkgs.hyprland;
    plugins = [ ];
    systemd = {
      enable = true;
      variables = [ "--all" ];
    };
    xwayland.enable = true;
    settings = {
      "$terminal" = "ghostty";
      "$fileManager" = "nautilus";
      "$browser" = "firefox";

      exec-once = [
        "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "~/.config/hypr/scripts/xdg.sh &"
        # "= swaync &"
        "hypridle"
        "waybar &"
        "hyprpaper &"
        "blueman-applet"
        # "nm-applet --indicator"
        "wl-paste --watch cliphist store"
      ];

      # For all categories, see https://wiki.hyprland.org/Configuring/Variables/
      input = {
        kb_layout = "us";
        # kb_variant =
        # kb_model =
        kb_options = "compose:ralt,caps:escape";
        # kb_rules =
        follow_mouse = 1;
        touchpad = { natural_scroll = false; };
        sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
      };

      general = {
        # See https://wiki.hyprland.org/Configuring/Variables/ for more
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        #col.active_border = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        #col.inactive_border = "rgba(595959aa)";
        layout = "dwindle";
        # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
        allow_tearing = false;
      };

      decoration = {
        # See https://wiki.hyprland.org/Configuring/Variables/ for more
        rounding = 10;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
          vibrancy = 0.1696;
        };
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
      };

      animations = {
        enabled = true;
        # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      dwindle = {
        # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
        pseudotile =
          true; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
        preserve_split = true; # you probably want this
      };

      master = {
        # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
        new_status = "master";
      };

      gestures = {
        # See https://wiki.hyprland.org/Configuring/Variables/ for more
        workspace_swipe = true;
      };

      misc = {
        # See https://wiki.hyprland.org/Configuring/Variables/ for more
        force_default_wallpaper =
          0; # Set to 0 to disable the anime mascot wallpapers
        disable_hyprland_logo = true;
      };

      # Example per-device config
      # See https://wiki.hyprland.org/Configuring/Keywords/#per-device-input-configs for more
      device = {
        name = "epic-mouse-v1";
        sensitivity = -0.5;
      };

      env = [
        "XCURSOR_SIZE,24"
        "QT_QPA_PLATFORMTHEME,qt5ct" # change to qt6ct if you have that
        "QT_QPA_PLATFORM,wayland"
        "GTK_THEME,Adwaita:dark"
        "XDG_SCREENSHOTS_DIR,$HOME/Pictures/Screenshots"
        "XDG_CURRENT_DESKTOP, Hyprland"
        "XDG_SESSION_TYPE, wayland"
        "XDG_SESSION_DESKTOP, Hyprland"
      ];

      windowrulev2 = [
        "opacity 1.0 0.95,class:.*" # Shows all inactive windows with opacity 0.9
        "float,class:^(pavucontrol)$"
        "float,class:^(blueman-manager)$"
        "float,class:^(nm-applet)$"
        "float,class:^(nm-connection-editor)$"
        "float,class:^(polkit-gnome-authentication-agent-1)$"
        "float,title:^(1Password)$"
        "float,class:^(org.keepassxc.KeePassXC)$"
        "size 900 700,class:^(org.keepassxc.KeePassXC)$"
        "float,class:^(org.manjaro.pamac.manager)$"
        "size 900 700,class:^(org.manjaro.pamac.manager)$"
        "center,class:^(org.manjaro.pamac.manager)$"
        "float,class:^(SshAskpass)$"
        "float,class:^(Nsxiv)$"
        "center,class:^(Nsxiv)$"
        "size 900 700,class:^(Nsxiv)$"
        "float,title:^(Save File|Open File|Save As)"
        "size 900 700,title:^(Save File|Open File|Save As)"
        "float,title:^(Administrator privileges required)$"
        "float,class:^(gedit)$"
        "center,class:^(gedit)$"
        "size 900 700,class:^(gedit)$"
        "float,class:^(MPlayer)$"
        "center,class:^(MPlayer)$"
        "size 900 700,class:^(MPlayer)$"
        "float,title:^(Administrator privileges required)$"
        "float,class:^(org.gnome.NautilusPreviewer)$"
        "center,class:^(org.gnome.NautilusPreviewer)$"
        "size 900 700,class:^(org.gnome.NautilusPreviewer)"
        "float,class:^(virt-manager)$"
        "float,class:^(Rofi)$"
        "center,class:^(Rofi)$"
        "stayfocused,class:^(Rofi)$"
        # Rules for the Gnome notes app
        "float,title:^(New and Recent)$"
        "size 900 700,title:^(New and Recent)"
        # Rules for for the modal GTK file picker dialogs""
        "center,title:^(All Files)$"
        "size 800 600,title:^(All Files)"
        # Firefox rules
        "float,class:(firefox),title:(Library)"
        "size 1200 800,class:(firefox),title:(Library)"
        # Warp
        "tile,class:(dev.warp.Warp)"
      ];

    };
    extraConfig = ''
      ${extraMonitorSettings}

      $mainMod = SUPER

      bind = $mainMod, RETURN, exec, $terminal

      bind = $mainMod, F, fullscreen
      bind = $mainMod, V, togglefloating,
      bind = $mainMod, D, exec, rofi -show drun
      bind = $mainMod, B, exec, $browser
      bind = $mainMod, P, pseudo, # dwindle
      bind = $mainMod, J, togglesplit, # dwindle
      bind = $mainMod, W, exec, warp

      bind = $mainMod SHIFT, RETURN, exec, $fileManager
      bind = $mainMod SHIFT, Q, killactive,
      bind = $mainMod SHIFT, E, exec, wlogout
      bind = $mainMod SHIFT, L, exec, hyprlock
      bind = $mainMod SHIFT, H, exec, ~/.config/waybar/scripts/keyhint.sh
      bind = $mainMod SHIFT, P, exec, ~/.config/waybar/scripts/cliphist.sh
      bind = $mainMod SHIFT, S, exec, systemctl suspend
      bind = $mainMod SHIFT, Y, exec, grim -g "$(slurp -d)" - | swappy -f -

      bind = $mainMod, SPACE, exec, rofi -show run

      # Special workspace (scratchpad)
      $key_dash = code:20
      bind = $mainMod SHIFT, $key_dash, movetoworkspace, special:magic
      bind = $mainMod, S, togglespecialworkspace, magic
      bind = $mainMod, $key_dash, togglespecialworkspace, magic

      # Move focus with mainMod + arrow keys
      bind = $mainMod, left, movefocus, l
      bind = $mainMod, right, movefocus, r
      bind = $mainMod, up, movefocus, u
      bind = $mainMod, down, movefocus, d
      # Move focus with mainMod + SHIFT + arrow keys
      bind = $mainMod SHIFT, left, movewindow, l
      bind = $mainMod SHIFT, right, movewindow, r
      bind = $mainMod SHIFT, up, movewindow, u
      bind = $mainMod SHIFT, down, movewindow, d

      # Switch workspaces with mainMod + [0-9]
      bind = $mainMod, 1, workspace, 1
      bind = $mainMod, 2, workspace, 2
      bind = $mainMod, 3, workspace, 3
      bind = $mainMod, 4, workspace, 4
      bind = $mainMod, 5, workspace, 5
      bind = $mainMod, 6, workspace, 6
      bind = $mainMod, 7, workspace, 7
      bind = $mainMod, 8, workspace, 8
      bind = $mainMod, 9, workspace, 9
      bind = $mainMod, 0, workspace, 10
      bind = $mainMod, HOME, workspace, 1
      bind = $mainMod, END, workspace, 10

      # Move active window to a workspace with mainMod + SHIFT + [0-9]
      bind = $mainMod SHIFT, 1, movetoworkspace, 1
      bind = $mainMod SHIFT, 2, movetoworkspace, 2
      bind = $mainMod SHIFT, 3, movetoworkspace, 3
      bind = $mainMod SHIFT, 4, movetoworkspace, 4
      bind = $mainMod SHIFT, 5, movetoworkspace, 5
      bind = $mainMod SHIFT, 6, movetoworkspace, 6
      bind = $mainMod SHIFT, 7, movetoworkspace, 7
      bind = $mainMod SHIFT, 8, movetoworkspace, 8
      bind = $mainMod SHIFT, 9, movetoworkspace, 9
      bind = $mainMod SHIFT, 0, movetoworkspace, 10

      bind = $mainMod ALT, left, workspace, e-1
      bind = $mainMod ALT, right, workspace, e+1

      # Scroll through existing workspaces with mainMod + scroll
      bind = $mainMod, mouse_down, workspace, e+1
      bind = $mainMod, mouse_up, workspace, e-1

      # Move/resize windows with mainMod + LMB/RM
      bindm = $mainMod, mouse:272, movewindow
      bindm = $mainMod SHIFT, mouse:272, resizewindow
      #
      # Fn keys
      bind = , XF86MonBrightnessUp, exec, brightnessctl -q s +10%
      bind = , XF86MonBrightnessDown, exec, brightnessctl -q s 10%-
      bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
      bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
      bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      bind = , XF86AudioPlay, exec, notify-send "Play"
      bind = , XF86AudioPause, exec, mocp --pause
      bind = , XF86AudioNext, exec, mocp --next
      bind = , XF86AudioPrev, exec, mocp --previous
      bind = , XF86AudioMicMute, exec, pactl set-source-mute @DEFAULT_SOURCE@ toggle
      bind = , XF86Calculator, exec, qalculate-gtk
      bind = , XF86Lock, exec, swaylock

      # to switch between windows in a floating workspace
      bind = SUPER,Tab,cyclenext,          # change focus to another window
      bind = SUPER,Tab,bringactivetotop,   # bring it to the top

      # will switch to a submap called resize
      bind=ALT,R,submap,resize
      # will start a submap called "resize"
      submap=resize
      # sets repeatable binds for resizing the active window
      binde=,right,resizeactive,10 0
      binde=,left,resizeactive,-10 0
      binde=,up,resizeactive,0 -10
      binde=,down,resizeactive,0 10
      # use reset to go back to the global submap
      bind=,escape,submap,reset 
      # will reset the submap, meaning end the current one and return to the global one
      submap=reset
    '';
  };

  home.pointerCursor = {
    gtk.enable = true;
    # x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 16;
  };

  gtk = {
    enable = true;

    theme = {
      package = pkgs.flat-remix-gtk;
      name = "Flat-Remix-GTK-Grey-Darkest";
    };

    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };

    font = {
      name = "Sans";
      size = 11;
    };
  };
}
