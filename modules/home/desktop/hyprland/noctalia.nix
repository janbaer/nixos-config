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
        Lock the screen before suspend so waking requires the PAM password. When
        enabled (default), this covers all suspend paths: idle and session-menu
        suspend honour Noctalia's general.lockOnSuspend, and a hypridle pre-sleep
        hook covers external suspends (lid close, power key, systemctl suspend) that
        Noctalia has no logind inhibitor for. Disable on trusted hosts (e.g. a
        desktop): no hypridle hook and general.lockOnSuspend is forced false, so the
        screen never auto-locks and no password is demanded.
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.noctalia-shell.enable = true;

    # Use the cached nixpkgs build instead of the flake's default package, which
    # compiles the quickshell fork from source on every machine. nixpkgs ships
    # noctalia-shell (same v4 line, settingsVersion 59) plus the fork as the
    # cached `noctalia-qs` package, so this substitutes from cache.nixos.org with
    # no local build and no behavioural change. Version now tracks the nixpkgs
    # input; the flake input is retained for its home module + as a pinned fallback.
    programs.noctalia-shell.package = pkgs.noctalia-shell;

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
          {
            id = "Workspace";
            # Show the app icons of the windows open in each workspace (resolved
            # via the Papirus theme), not just on hover. Replaces waybar's static
            # per-workspace glyphs. The index number still shows (default labelMode).
            showApplications = true;
            showApplicationsHover = false;
          }
        ];
        center = [
          { id = "MediaMini"; }
          { id = "Clock"; }
          { id = "SystemMonitor"; }
          { id = "ActiveWindow"; }
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

    # Lock before external suspends (lid close, power key, `systemctl suspend`).
    # Noctalia's lockOnSuspend only covers idle- and session-menu-initiated suspend;
    # it has no logind PrepareForSleep inhibitor. hypridle runs purely as a pre-sleep
    # locker here (no idle listeners — Noctalia's IdleService owns idle), taking a
    # logind delay-inhibitor so the lock engages before the system sleeps.
    services.hypridle = mkIf cfg.autoLock.enable {
      enable = true;
      settings.general = {
        lock_cmd = "${config.programs.noctalia-shell.package}/bin/noctalia-shell ipc call lockScreen lock";
        before_sleep_cmd = "${config.programs.noctalia-shell.package}/bin/noctalia-shell ipc call lockScreen lock";
      };
    };
  };
}
