{
  config,
  lib,
  pkgs,
  hostname,
  ...
}:
let
  inherit (import ./../../../../hosts/${hostname}/variables.nix)
    useHyprland
    monitors
    ;

  inherit (lib.generators) mkLuaInline;

  # Dispatcher helpers — each renders a raw `hl.dsp.*` Lua expression.
  exec = cmd: mkLuaInline ''hl.dsp.exec_cmd("${cmd}")'';
  killActive = mkLuaInline "hl.dsp.window.close()";
  toggleFloat = mkLuaInline ''hl.dsp.window.float({ action = "toggle" })'';
  fullscreen = mkLuaInline ''hl.dsp.window.fullscreen({ action = "toggle" })'';
  pseudo = mkLuaInline "hl.dsp.window.pseudo()";
  layoutMsg = msg: mkLuaInline ''hl.dsp.layout("${msg}")'';
  focusDir = dir: mkLuaInline ''hl.dsp.focus({ direction = "${dir}" })'';
  moveDir = dir: mkLuaInline ''hl.dsp.window.move({ direction = "${dir}" })'';
  focusWs = ws: mkLuaInline ''hl.dsp.focus({ workspace = "${ws}" })'';
  moveToWs = ws: mkLuaInline ''hl.dsp.window.move({ workspace = "${ws}" })'';
  toggleSpecial = name: mkLuaInline ''hl.dsp.workspace.toggle_special("${name}")'';
  submap = name: mkLuaInline ''hl.dsp.submap("${name}")'';
  drag = mkLuaInline "hl.dsp.window.drag()";
  mouseResize = mkLuaInline "hl.dsp.window.resize()";

  # Noctalia shell integration. When the Noctalia module is enabled for the host,
  # these actions call its Quickshell IPC (via the noctalia-shell wrapper) instead
  # of the standalone rofi / wlogout / hyprlock / cliphist stack. Hosts without
  # Noctalia keep the original commands, so the rewrite is safe per-host.
  noctaliaEnabled = config.modules.desktop.noctalia.enable;
  ipc = target: fn: exec "noctalia-shell ipc call ${target} ${fn}";
  launcherDrun = if noctaliaEnabled then ipc "launcher" "toggle" else exec "rofi -show drun";
  launcherRun = if noctaliaEnabled then ipc "launcher" "command" else exec "rofi -show run";
  clipboardMenu =
    if noctaliaEnabled then ipc "launcher" "clipboard" else exec "~/.config/waybar/scripts/cliphist.sh";
  sessionMenu = if noctaliaEnabled then ipc "sessionMenu" "toggle" else exec "wlogout";
  lockScreen = if noctaliaEnabled then ipc "lockScreen" "lock" else exec "hyprlock";

  # Volume/brightness via Noctalia IPC so its OSD shows; the bare wpctl/brightnessctl
  # binds fire silently. Falls back to the silent commands where Noctalia is off.
  volUp = if noctaliaEnabled then ipc "volume" "increase" else exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
  volDown = if noctaliaEnabled then ipc "volume" "decrease" else exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
  volMute = if noctaliaEnabled then ipc "volume" "muteOutput" else exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
  micMute = if noctaliaEnabled then ipc "volume" "muteInput" else exec "pactl set-source-mute @DEFAULT_SOURCE@ toggle";
  brightUp = if noctaliaEnabled then ipc "brightness" "increase" else exec "brightnessctl -q s +10%";
  brightDown = if noctaliaEnabled then ipc "brightness" "decrease" else exec "brightnessctl -q s 10%-";

  # `bind = [keys dispatcher]` and `bindOpts = [keys dispatcher opts]` map onto
  # the home-manager `_args` form, which renders as `hl.bind(keys, dispatcher[, opts])`.
  bind = keys: dispatcher: {
    _args = [
      keys
      dispatcher
    ];
  };
  bindOpts = keys: dispatcher: opts: {
    _args = [
      keys
      dispatcher
      opts
    ];
  };

  # SUPER + N focuses workspace N, SUPER + SHIFT + N moves the active window there.
  # Key 0 maps to workspace 10, matching the previous hyprlang config.
  workspaceBinds = lib.concatMap (
    i:
    let
      key = toString (lib.mod i 10);
    in
    [
      (bind "SUPER + ${key}" (focusWs (toString i)))
      (bind "SUPER + SHIFT + ${key}" (moveToWs (toString i)))
    ]
  ) (lib.range 1 10);

  # Applications previously launched via the hyprlang `exec-once` list. The
  # systemd integration registers its own `hyprland.start` hook; `hl.on` is an
  # event subscription, so this second hook coexists with it.
  startupCommands = [
    "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    "~/.config/hypr/scripts/xdg.sh &"
    "hypridle"
    "hyprpaper"
    "blueman-applet"
  ]
  # waybar and the standalone cliphist watcher are superseded by Noctalia's bar
  # and its built-in clipboard watcher when the shell is enabled.
  ++ lib.optionals (!noctaliaEnabled) [
    "waybar &"
    "wl-paste --watch cliphist store"
  ]
  # Launch the Noctalia shell from the compositor. The v4 home module's systemd
  # service is deprecated, so the Hyprland startup hook is the supported method.
  ++ lib.optionals noctaliaEnabled [
    "noctalia-shell"
  ];
  # Lua long-string `[[ ]]` avoids escaping; commands with `"` would otherwise
  # produce broken Lua. (None contain `]]`, which long-strings can't hold.)
  startupHook = mkLuaInline ''
    function()
    ${lib.concatMapStrings (c: "  hl.exec_cmd([[${c}]])\n") startupCommands}end'';
in
{
  wayland.windowManager.hyprland = {
    enable = useHyprland;
    configType = "lua";
    package = pkgs.hyprland;
    plugins = [ ];
    systemd = {
      enable = true;
      variables = [ "--all" ];
    };
    xwayland.enable = true;
    settings = {
      # Per-host monitor layout. Each attrset renders as one `hl.monitor({...})`.
      monitor = monitors;

      env = [
        {
          _args = [
            "XCURSOR_SIZE"
            "24"
          ];
        }
        {
          _args = [
            "QT_QPA_PLATFORMTHEME"
            "qt5ct"
          ];
        }
        {
          _args = [
            "QT_QPA_PLATFORM"
            "wayland"
          ];
        }
        {
          _args = [
            "GTK_THEME"
            "Adwaita:dark"
          ];
        }
        {
          _args = [
            "XDG_SCREENSHOTS_DIR"
            "$HOME/Pictures/Screenshots"
          ];
        }
        {
          _args = [
            "XDG_CURRENT_DESKTOP"
            "Hyprland"
          ];
        }
        {
          _args = [
            "XDG_SESSION_TYPE"
            "wayland"
          ];
        }
        {
          _args = [
            "XDG_SESSION_DESKTOP"
            "Hyprland"
          ];
        }
      ];

      # Option categories — renders as a single `hl.config({...})` call.
      # See https://wiki.hypr.land/Configuring/Variables/
      config = {
        input = {
          kb_layout = "us";
          kb_options = "compose:ralt,caps:escape";
          follow_mouse = 1;
          touchpad = {
            natural_scroll = false;
          };
          sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
        };

        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
          layout = "dwindle";
          allow_tearing = false;
        };

        decoration = {
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

        # Bezier curves and per-leaf animations are separate `hl.curve`/
        # `hl.animation` calls below; only the master toggle lives here.
        animations = {
          enabled = true;
        };

        dwindle = {
          preserve_split = true;
        };

        master = {
          new_status = "master";
        };

        misc = {
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
        };
      };

      gesture = {
        fingers = 3;
        direction = "horizontal";
        action = "workspace";
      };

      # `curve` is in home-manager's importantPrefixes, so it is emitted before
      # the animations that reference `myBezier`.
      curve = [
        {
          _args = [
            "myBezier"
            {
              type = "bezier";
              points = mkLuaInline "{ {0.05, 0.9}, {0.1, 1.05} }";
            }
          ];
        }
      ];

      animation = [
        {
          leaf = "windows";
          enabled = true;
          speed = 7;
          bezier = "myBezier";
        }
        {
          leaf = "windowsOut";
          enabled = true;
          speed = 7;
          bezier = "default";
          style = "popin 80%";
        }
        {
          leaf = "border";
          enabled = true;
          speed = 10;
          bezier = "default";
        }
        {
          leaf = "borderangle";
          enabled = true;
          speed = 8;
          bezier = "default";
        }
        {
          leaf = "fade";
          enabled = true;
          speed = 7;
          bezier = "default";
        }
        {
          leaf = "workspaces";
          enabled = true;
          speed = 6;
          bezier = "default";
        }
      ];

      # `match` holds the regex selectors; remaining keys are rule effects.
      # `size` takes a Lua vec2 table `{ w, h }`, so it is a Nix list here.
      window_rule = [
        {
          name = "global-window-rule";
          match = {
            class = ".*";
          };
          opacity = "1.0 0.95";
        }

        {
          name = "bluetooth-devices-rule";
          match = {
            title = "^(Bluetooth Devices)$";
          };
          float = true;
        }
        {
          name = "nmapplet-rule";
          match = {
            class = "^(nm-applet)$";
          };
          float = true;
        }
        {
          name = "nm-connection-editor-rule";
          match = {
            class = "^(nm-connection-editor)$";
          };
          float = true;
        }
        {
          name = "polkit-rule";
          match = {
            class = "^(polkit-gnome-authentication-agent-1)$";
          };
          float = true;
        }
        {
          name = "1password-rule";
          match = {
            title = "^(1Password)$";
          };
          float = true;
        }
        {
          name = "ssh-askpass-rule";
          match = {
            class = "^(SshAskpass)$";
          };
          float = true;
        }
        {
          name = "virt-manager-rule";
          match = {
            class = "^(virt-manager)$";
          };
          float = true;
        }
        {
          name = "sudo-rule";
          match = {
            title = "^(Administrator privileges required)$";
          };
          float = true;
        }

        {
          name = "keepassxc-rule";
          match = {
            class = "^(org.keepassxc.KeePassXC)$";
          };
          float = true;
          size = [
            900
            700
          ];
        }
        {
          name = "nsxiv-rule";
          match = {
            class = "^(Nsxiv)$";
          };
          float = true;
          center = true;
          size = [
            900
            700
          ];
        }
        {
          name = "gedit-rule";
          match = {
            class = "^(gedit)$";
          };
          float = true;
          center = true;
          size = [
            900
            700
          ];
        }
        {
          name = "mpv-rule";
          match = {
            class = "^(MPlayer|mpv)$";
          };
          float = true;
          center = true;
          size = [
            900
            700
          ];
        }
        {
          name = "nautilus-preview-rule";
          match = {
            class = "^(org.gnome.NautilusPreviewer)$";
          };
          float = true;
          center = true;
          size = [
            900
            700
          ];
        }

        {
          name = "rofi-rule";
          match = {
            class = "^(Rofi)$";
          };
          float = true;
          center = true;
          stay_focused = true;
        }

        {
          name = "gnome-notes-rule";
          match = {
            title = "^(New and Recent)$";
          };
          float = true;
          size = [
            900
            700
          ];
        }
        {
          name = "gtk-modal-dialog-rule";
          match = {
            class = "^(xdg-desktop-portal-gtk)$";
          };
          float = true;
          center = true;
          size = [
            900
            700
          ];
        }
        {
          name = "firefox-library-rule";
          match = {
            class = "(firefox)";
            title = "(Library)";
          };
          float = true;
          size = [
            1200
            800
          ];
        }
        {
          name = "thunder-bird-edit-rule";
          match = {
            title = "^(Edit Item)$";
          };
          float = true;
          center = true;
        }
      ];

      on = [
        {
          _args = [
            "hyprland.start"
            startupHook
          ];
        }
      ];

      bind = [
        (bind "SUPER + RETURN" (exec "ghostty"))
        (bind "SUPER + F" fullscreen)
        (bind "SUPER + V" toggleFloat)
        (bind "SUPER + D" launcherDrun)
        (bind "SUPER + B" (exec "firefox"))
        (bind "SUPER + P" pseudo) # dwindle
        (bind "SUPER + J" (layoutMsg "togglesplit")) # dwindle

        (bind "SUPER + SHIFT + RETURN" (exec "nautilus"))
        (bind "SUPER + SHIFT + Q" killActive)
        (bind "SUPER + SHIFT + E" sessionMenu)
        (bind "SUPER + SHIFT + L" lockScreen)
        (bind "SUPER + SHIFT + H" (exec "~/.config/waybar/scripts/keyhint.sh"))
        (bind "SUPER + SHIFT + P" clipboardMenu)
        (bind "SUPER + SHIFT + S" (exec "systemctl suspend"))
        # Lua long-string `[[ ]]` avoids escaping the inner shell quotes.
        (bind "SUPER + SHIFT + Y" (
          mkLuaInline ''hl.dsp.exec_cmd([[grim -g "$(slurp -d)" - | swappy -f -]])''
        ))

        (bind "SUPER + SPACE" launcherRun)

        # Special workspace (scratchpad). code:20 is the dash/minus key.
        (bind "SUPER + SHIFT + code:20" (moveToWs "special:magic"))
        (bind "SUPER + S" (toggleSpecial "magic"))
        (bind "SUPER + code:20" (toggleSpecial "magic"))

        # Move focus with SUPER + arrow keys
        (bind "SUPER + left" (focusDir "l"))
        (bind "SUPER + right" (focusDir "r"))
        (bind "SUPER + up" (focusDir "u"))
        (bind "SUPER + down" (focusDir "d"))

        # Move window with SUPER + SHIFT + arrow keys
        (bind "SUPER + SHIFT + left" (moveDir "l"))
        (bind "SUPER + SHIFT + right" (moveDir "r"))
        (bind "SUPER + SHIFT + up" (moveDir "u"))
        (bind "SUPER + SHIFT + down" (moveDir "d"))

        (bind "SUPER + HOME" (focusWs "1"))
        (bind "SUPER + END" (focusWs "10"))

        # Relative workspace switching
        (bind "SUPER + ALT + left" (focusWs "e-1"))
        (bind "SUPER + ALT + right" (focusWs "e+1"))
        (bind "SUPER + mouse_down" (focusWs "e+1"))
        (bind "SUPER + mouse_up" (focusWs "e-1"))

        # Move/resize windows with SUPER + LMB/RMB
        (bindOpts "SUPER + mouse:272" drag { mouse = true; })
        (bindOpts "SUPER + SHIFT + mouse:272" mouseResize { mouse = true; })

        # Function keys
        (bind "XF86MonBrightnessUp" brightUp)
        (bind "XF86MonBrightnessDown" brightDown)
        (bind "XF86AudioRaiseVolume" volUp)
        (bind "XF86AudioLowerVolume" volDown)
        (bind "XF86AudioMute" volMute)
        (bind "XF86AudioPlay" (exec "playerctl play-pause"))
        (bind "XF86AudioPause" (exec "playerctl play-pause"))
        (bind "XF86AudioNext" (exec "playerctl next"))
        (bind "XF86AudioPrev" (exec "playerctl previous"))
        (bind "XF86AudioMicMute" micMute)
        (bind "XF86Calculator" (exec "qalculate-gtk"))
        (bind "XF86ScreenSaver" lockScreen)

        # Enter the resize submap
        (bind "ALT + R" (submap "resize"))
      ]
      ++ workspaceBinds;

      # Resize submap: arrow keys resize the active window, escape returns to the
      # global submap. `reset` is reserved by home-manager for the default submap.
      define_submap = {
        _args = [
          "resize"
          (mkLuaInline ''
            function()
              hl.bind("right", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
              hl.bind("left", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
              hl.bind("up", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
              hl.bind("down", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })
              hl.bind("escape", hl.dsp.submap("reset"))
            end'')
        ];
      };
    };
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
    gtk4.theme = null;
    theme = {
      package = pkgs.gnome-themes-extra;
      name = "Adwaita-dark";
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

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      gtk-theme = "Adwaita-dark";
      color-scheme = "prefer-dark";
    };
  };
}
