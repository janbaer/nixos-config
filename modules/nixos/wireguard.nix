{ config, lib, pkgs, username, hostname, ... }:
with lib;
let
  wgInterfaceName = "wg0";
  wgUdpPort = 1194;

  cfg = config.modules.wireguard;
in {
  options.modules.wireguard.enable = mkEnableOption "Wireguard";

  config = mkIf cfg.enable {
    age = {
      secrets = {
        "wg0-conf-${hostname}" = {
          file = ../../secrets/wg0-conf-${hostname}.age;
          path = "/home/${username}/.config/wireguard/${wgInterfaceName}.conf";
          owner = "${username}";
          mode = "0600";
          symlink = false;
        };
      };
    };

    environment.systemPackages = with pkgs; [ wireguard-tools ];

    networking.firewall = {
      allowedUDPPorts = [ wgUdpPort ];
      trustedInterfaces = [ "wg+" ];  # Trust all wireguard interfaces
      checkReversePath = false;
    };

    system.activationScripts.wireguardConfiguration.text = ''
      if ! /run/current-system/sw/bin/nmcli connection show | grep -q "wg0"; then
        echo "WireGuard VPN connection not found. Importing configuration..."
        /run/current-system/sw/bin/nmcli connection import type wireguard file /home/${username}/.config/wireguard/wg0.conf
      else
        echo "WireGuard VPN connection already exists."
      fi
    '';
  };
}
