{ config, lib, inputs, ... }:
with lib;
let
  cfg = config.modules.desktop.noctalia;
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

      # Bar layout mirrors Noctalia's default, plus the built-in WireGuard VPN
      # widget (nmcli-backed, replaces the old waybar custom/vpn module from #14).
      # On the VM it shows "disconnected" (no profiles); hardware-tested on jabasoft-tx.
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
          { id = "VPN"; }
          { id = "Battery"; }
          { id = "Volume"; }
          { id = "Brightness"; }
          { id = "ControlCenter"; }
        ];
      };
    };
  };
}
