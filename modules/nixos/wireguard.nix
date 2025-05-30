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

    # https://wiki.nixos.org/wiki/WireGuard
    # The following configuration was not usable from the Networkmanager
    # It was causing problems while accessing the privateKey because of permisson denied errors
    # networking.wireguard = {
    #   enable = true;
    #   interfaces = {
    #     wg0 = {
    #       ips = [ wgIPAddress ];
    #       peers = [{
    #         publicKey = wgPublicKey;
    #         endpoint = wgEndpoint;
    #         persistentKeepalive = 25;
    #         allowedIPs = wgAllowedIPs;
    #       }];
    #       privateKeyFile = config.age.secrets."wg-private-key-${hostname}".path;
    #     };
    #   };
    # };

    networking.firewall = {
      allowedUDPPorts = [ wgUdpPort ];
      trustedInterfaces = [ "wg+" ];  # Trust all wireguard interfaces
      checkReversePath = false;
    };

    system.activationScripts.script.text = ''
      #!/usr/bin/env bash
      if ! /run/current-system/sw/bin/nmcli connection show | grep -q "wg0"; then
        echo "WireGuard VPN connection not found. Importing configuration..."
        /run/current-system/sw/bin/nmcli connection import type wireguard file /home/${username}/.config/wireguard/wg0.conf
      else
        echo "WireGuard VPN connection already exists."
      fi
    '';
  };
}
