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

  # Left-click VPN toggle for the bar, built from a CustomButton instead of the
  # built-in VPN widget (which only exposes a right-click menu). The scripts are
  # Nix-generated store paths, so nothing lives out-of-band. nmcli is pinned;
  # Noctalia runs both via `sh -lc`.
  vpnConnection = "wg0";
  vpnToggle = pkgs.writeShellScript "noctalia-vpn-toggle" ''
    if ${pkgs.networkmanager}/bin/nmcli -t -f NAME connection show --active | grep -qx ${vpnConnection}; then
      ${pkgs.networkmanager}/bin/nmcli connection down ${vpnConnection}
    else
      ${pkgs.networkmanager}/bin/nmcli connection up ${vpnConnection}
    fi
  '';
  # Emits JSON consumed by CustomButton's parseJson: swaps the icon shield <-> shield-lock,
  # tints it when connected, and sets the tooltip. No "text" field keeps it icon-only.
  vpnStatus = pkgs.writeShellScript "noctalia-vpn-status" ''
    if ${pkgs.networkmanager}/bin/nmcli -t -f NAME connection show --active | grep -qx ${vpnConnection}; then
      printf '{"icon":"shield-lock","tooltip":"VPN %s connected","iconColor":"primary"}' ${vpnConnection}
    else
      printf '{"icon":"shield","tooltip":"VPN off"}'
    fi
  '';
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  options.modules.desktop.noctalia = {
    enable = mkEnableOption "Noctalia desktop shell (Quickshell, v4 stable line)";

    vpnToggle.enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Show the WireGuard (${vpnConnection}) left-click toggle CustomButton in
        the bar. Disable on hosts without a ${vpnConnection} connection
        (e.g. desktops), where the button would only ever read "VPN off".
      '';
    };

    autoLock.enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Auto-lock the screen on suspend (the lock screen then requires the PAM
        password to unlock). Disable on trusted hosts (e.g. a desktop) where you
        don't want to be prompted for a password — the screen never auto-locks.
        Noctalia has no "skip password" toggle, so this works by suppressing the
        lock trigger entirely (general.lockOnSuspend). Manual locking, if invoked,
        still authenticates via PAM.
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.noctalia-shell.enable = true;

    # Declarative settings. The home module writes ~/.config/noctalia/settings.json
    # as a read-only Nix-store symlink; pinning settingsVersion to the schema
    # version shipped by this input (59) keeps Noctalia from running migrations and
    # attempting a write-back on launch. Quickshell's JsonAdapter deep-merges this
    # partial set over the built-in defaults, so only deviations are listed here.
    programs.noctalia-shell.settings = {
      settingsVersion = 59;

      # cliphist-backed clipboard history (SUPER+SHIFT+P launcher mode). Noctalia
      # runs its own wl-paste watcher, so the standalone one is dropped in hyprland.nix.
      appLauncher.enableClipboardHistory = true;

      # Noctalia defaults to ~/Pictures/Wallpapers (capital W); our directory is
      # lowercase. Point it at the real location (shared via common variables).
      wallpaper.directory = "${config.home.homeDirectory}/${wallpaperDir}";

      # Fire session actions (logout/lock/reboot/shutdown) immediately instead of
      # running a 10s countdown first.
      sessionMenu.enableCountdown = false;

      # Bar layout mirrors Noctalia's default. The WireGuard toggle is a
      # CustomButton (left-click connect/disconnect wg0, icon reflects state via
      # the status script's JSON), replacing the old waybar custom/vpn module (#14)
      # and the built-in VPN widget's right-click-only menu.
      bar.widgets = {
        left = [
          { id = "Launcher"; }
          { id = "Clock"; }
          { id = "SystemMonitor"; }
          { id = "ActiveWindow"; }
          { id = "MediaMini"; }
        ];
        center = [
          {
            id = "Workspace";
            # Show the app icons of the windows open in each workspace (resolved
            # via the Papirus theme), not just on hover. Replaces waybar's static
            # per-workspace glyphs. The index number still shows (default labelMode).
            showApplications = true;
            showApplicationsHover = false;
          }
        ];
        right = [
          { id = "Tray"; }
          { id = "NotificationHistory"; }
        ]
        ++ optional cfg.vpnToggle.enable {
          id = "CustomButton";
          icon = "shield";
          parseJson = true;
          textStream = false;
          textIntervalMs = 3000;
          leftClickUpdateText = true;
          leftClickExec = "${vpnToggle}";
          textCommand = "${vpnStatus}";
        }
        ++ [
          { id = "Battery"; }
          { id = "Volume"; }
          { id = "Brightness"; }
          { id = "ControlCenter"; }
        ];
      };
    }
    // optionalAttrs (!cfg.autoLock.enable) {
      # Trusted host: never auto-lock, so the PAM password is never demanded.
      general.lockOnSuspend = false;
    };
  };
}
