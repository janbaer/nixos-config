{ config, lib, pkgs, inputs, ... }:
with lib;
let
  cfg = config.modules.desktop.noctalia;

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

  options.modules.desktop.noctalia.enable =
    mkEnableOption "Noctalia desktop shell (Quickshell, v4 stable line)";

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
      # lowercase. Point it at the real location.
      wallpaper.directory = "${config.home.homeDirectory}/Pictures/wallpapers";

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
          { id = "Workspace"; }
        ];
        right = [
          { id = "Tray"; }
          { id = "NotificationHistory"; }
          {
            id = "CustomButton";
            icon = "shield";
            parseJson = true;
            textStream = false;
            textIntervalMs = 3000;
            leftClickUpdateText = true;
            leftClickExec = "${vpnToggle}";
            textCommand = "${vpnStatus}";
          }
          { id = "Battery"; }
          { id = "Volume"; }
          { id = "Brightness"; }
          { id = "ControlCenter"; }
        ];
      };
    };
  };
}
