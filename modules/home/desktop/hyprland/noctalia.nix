{
  config,
  lib,
  pkgs,
  inputs,
  hostname,
  ...
}:
with lib;
let
  cfg = config.modules.desktop.noctalia;
  inherit (import ./../../../../hosts/${hostname}/variables.nix) wallpaperDir;

  # Left-click VPN toggle for the bar. v5's custom_button is static (glyph, label,
  # tooltip), so the live connection state comes from a small plugin widget that
  # polls nmcli. Scripts and plugin are Nix-generated store paths, so nothing
  # lives out-of-band.
  vpnConnection = "wg0";
  vpnPluginId = "jan/vpn-toggle";
  nmcli = "${pkgs.networkmanager}/bin/nmcli";
  vpnToggle = pkgs.writeShellScript "noctalia-vpn-toggle" ''
    if ${nmcli} -t -f NAME connection show --active | grep -qx ${vpnConnection}; then
      ${nmcli} connection down ${vpnConnection}
    else
      ${nmcli} connection up ${vpnConnection}
    fi
  '';

  # A path plugin source: Noctalia scans <dir>/<plugin>/plugin.toml and treats the
  # directory as read-only. Swaps the icon shield <-> shield-lock and tints it
  # while connected.
  vpnPlugin = pkgs.linkFarm "noctalia-plugins" {
    "vpn-toggle/plugin.toml" = pkgs.writeText "plugin.toml" ''
      id = "${vpnPluginId}"
      name = "VPN toggle"
      version = "1.0.0"
      plugin_api = 3
      author = "jan"
      description = "Shows the ${vpnConnection} WireGuard state and toggles it on click."

      [[widget]]
      id = "status"
      entry = "status.luau"
    '';
    "vpn-toggle/status.luau" = pkgs.writeText "status.luau" ''
      local connection = "${vpnConnection}"

      local function render(active)
        if active then
          barWidget.setGlyph("shield-lock")
          barWidget.setGlyphColor("primary")
          barWidget.setTooltip("VPN " .. connection .. " connected")
        else
          barWidget.setGlyph("shield")
          barWidget.setGlyphColor("on_surface")
          barWidget.setTooltip("VPN off")
        end
      end

      local function refresh()
        noctalia.runAsync("${nmcli} -t -f NAME connection show --active", function(result)
          local active = false
          for line in string.gmatch(result.stdout, "[^\n]+") do
            if line == connection then
              active = true
              break
            end
          end
          render(active)
        end)
      end

      render(false)
      noctalia.setUpdateInterval(3000)

      function update()
        refresh()
      end

      function onClick()
        noctalia.runAsync("${vpnToggle}", function()
          refresh()
        end, 30000)
      end
    '';
  };

  # Idle behaviours have no notion of the power source, so the timeouts cannot be
  # made AC-conditional declaratively. The way in is caffeine: while it holds its
  # idle inhibitor, Noctalia suppresses every idle behaviour at once. AC-only power
  # detection matches refresh-rate.nix — only line-power devices expose `online`,
  # so the glob cannot match a battery.
  idleInhibitor = pkgs.writeShellScript "noctalia-idle-on-battery" ''
    last=""
    apply() {
      if ${pkgs.gnugrep}/bin/grep -qs '^1$' /sys/class/power_supply/*/online; then
        action=enable
      else
        action=disable
      fi
      [ "$action" = "$last" ] && return
      last=$action
      ${config.programs.noctalia.package}/bin/noctalia msg "caffeine-$action"
    }

    # A single AC/battery transition emits several PropertiesChanged signals, and
    # every repeat would clear a caffeine the user had just set by hand. The
    # first apply runs inside the pipeline so it shares $last with the loop —
    # ahead of it, in the parent shell, the assignment would not carry over.
    { echo; ${pkgs.glib}/bin/gdbus monitor --system \
        --dest org.freedesktop.UPower --object-path /org/freedesktop/UPower; } \
      | while read -r _; do apply; done
  '';
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  options.modules.desktop.noctalia = {
    enable = mkEnableOption "Noctalia desktop shell (v5)";

    vpnToggle.enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Show the WireGuard (${vpnConnection}) status widget in the bar; left-click
        toggles the connection. Disable on hosts without a ${vpnConnection}
        connection (e.g. desktops), where the widget would only ever read "VPN off".
      '';
    };

    autoLock.enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Lock the screen before suspend so waking requires the PAM password. When
        enabled (default), Noctalia locks on logind PrepareForSleep, which covers
        idle and session-menu suspend as well as external ones (lid close, power
        key, systemctl suspend). Disable on trusted hosts (e.g. a desktop): nothing
        locks before suspend and the idle lock stage is dropped, so no password is
        demanded.
      '';
    };

    idle.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Blank the display after 5 minutes of inactivity and suspend after 20.
        Noctalia's idle behaviours ship disabled, which is why nothing on this
        machine ever turned the panel off. Off by default — enable on laptops,
        where the panel is the single largest consumer on battery. A desktop
        that suspends on idle is usually a nuisance, not a saving.
      '';
    };

    idle.batteryOnly = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Hold Noctalia's caffeine inhibitor while on AC, so blank, lock and suspend
        only ever fire on battery. The inhibitor has no per-behaviour granularity —
        on AC the machine idles not at all and stays unlocked until suspended by
        hand. Shares the slot with a manual caffeine toggle, which the next
        AC/battery change therefore resets.
      '';
    };

    wifi.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Show the network widget in the bar: Wi-Fi signal-strength icon, SSID on
        hover, left-click opens the network tab of the control center, right-click
        disconnects or reconnects. Off by default — enable only on hosts with a
        wireless interface, since on wired-only machines the widget just shows a
        static ethernet icon.
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.noctalia.enable = true;

    # Use the cached nixpkgs build instead of the flake's default package, which
    # compiles from source on every machine. The flake input is pinned to the same
    # tag and only provides the home module.
    programs.noctalia.package = pkgs.noctalia;

    # Written to ~/.config/noctalia/config.toml and validated at build time. Values
    # changed in the Settings window land in ~/.local/state/noctalia/settings.toml,
    # which loads last and wins over this file. Only deviations from the built-in
    # defaults are listed here.
    programs.noctalia.settings = {
      # Noctalia defaults to the XDG Pictures directory; our wallpapers live
      # elsewhere (shared via common variables).
      wallpaper.directory = "${config.home.homeDirectory}/${wallpaperDir}";

      # SUPER+SPACE opens the launcher on this provider: whatever is typed after
      # "/run " runs as a shell command, like v4's ">cmd" launcher mode.
      shell.launcher.dmenu.entry.run = {
        label = "Run command";
        prefix = "run";
        glyph = "terminal";
        global = false;
        freeform = true;
        exec = "{query}";
      };

      bar.default = {
        # v5 insets the bar 100 px from each screen end; v4 ran edge to edge.
        margin_ends = 0;
        start = [
          "launcher"
          "taskbar"
        ];
        center = [
          "keyhint"
          "media"
          "cpu"
          "temp"
          "ram"
          "active_window"
        ];
        end = [
          "tray"
          "notifications"
        ]
        ++ optional cfg.vpnToggle.enable "vpn"
        ++ optional cfg.wifi.enable "network"
        ++ [
          "bluetooth"
          "volume"
          "brightness"
          "control-center"
          "battery"
          "clock"
        ];
      };

      widget = {
        # Show the app icons of the windows open in each workspace, grouped per
        # workspace. v5's workspaces widget only shows the focused app's icon.
        taskbar.group_by_workspace = true;

        # Keybindings cheat sheet (yad popup), so the binds stay discoverable
        # without having to remember SUPER+SHIFT+H, which also triggers it.
        keyhint = {
          type = "custom_button";
          glyph = "keyboard";
          tooltip = "Keyboard shortcuts";
          actions.left = "exec ${config.home.homeDirectory}/.config/hypr/scripts/keyhint.sh";
        };

        battery.display_mode = "graphic";

        clock.format = "{:%d.%m.%Y %H:%M}";
      }
      // optionalAttrs cfg.vpnToggle.enable {
        vpn.type = "${vpnPluginId}:status";
      };
    }
    // optionalAttrs cfg.vpnToggle.enable {
      plugins = {
        enabled = [ vpnPluginId ];
        source = [
          {
            name = "nixos-config";
            kind = "path";
            location = "${vpnPlugin}";
            enabled = true;
          }
        ];
      };
    }
    // optionalAttrs cfg.idle.enable {
      # Noctalia's idle behaviours, not a hypridle listener: it owns idle here, and
      # two idle daemons on the same session would blank and suspend twice.
      # The lock trails the blank by a minute, mirroring Noctalia's own default
      # spacing, so an unattended machine is not merely dark but locked.
      idle.behavior = {
        "screen-off" = {
          timeout = 300;
          action = "screen_off";
          enabled = true;
        };
        lock = {
          timeout = 360;
          action = "lock";
          enabled = cfg.autoLock.enable;
        };
        suspend = {
          timeout = 1200;
          action = "suspend";
          enabled = true;
          lock_before_suspend = cfg.autoLock.enable;
        };
      };
    }
    // optionalAttrs (!cfg.autoLock.enable) {
      # Trusted host: never lock before suspend, so the PAM password is never demanded.
      # This covers suspends via logind PrepareForSleep (lid close, systemctl
      # suspend); idle.behavior.suspend above has its own switch for idle-triggered
      # suspend. Both follow autoLock, so they never disagree.
      lockscreen.lock_before_suspend = false;
    }
    // optionalAttrs (cfg.idle.enable && cfg.idle.batteryOnly) {
      # The caffeine IPC calls below show an OSD on every change, which here would
      # pop up on each plug and unplug.
      osd.kinds.caffeine = false;
    };

    systemd.user.services.noctalia-idle-on-battery = mkIf (cfg.idle.enable && cfg.idle.batteryOnly) {
      Unit = {
        Description = "Suppress Noctalia's idle behaviours while on AC";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${idleInhibitor}";
        Restart = "on-failure";
        # Noctalia's IPC socket is not up the instant the session target is
        # reached; without a delay a failed start burns through the rate limit.
        RestartSec = "5s";
      };
      Install.WantedBy = [ "hyprland-session.target" ];
    };
  };
}
