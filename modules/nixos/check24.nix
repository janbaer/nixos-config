{ config, lib, pkgs, username, ... }:
with lib;
let
  cfg = config.modules.check24;

  c24VPNConnect = pkgs.writeShellScriptBin "c24-vpn-connect" ''
    #!/usr/bin/env bash
    openvpn3 session-start --config ~/Documents/bu/c24_office_de.ovpn
  '';

  c24VPNDisconnect = pkgs.writeShellScriptBin "c24-vpn-disconnect" ''
    #!/usr/bin/env bash
    openvpn3 sessions-list | grep "Path" | cut -d":" -f2 | cut -d ' ' -f2 | while read -r sessionpath; do
      openvpn3 session-manage --path "$sessionpath" --disconnect
    done
  '';
in {
  options.modules.check24.enable = mkEnableOption "Installation of OpenVPN3 and configurations related to CHECK24";

  config = mkIf cfg.enable {
    programs.check24 = { enable = true; };

    age = {
      secrets = {
        "check24-janbaer-ovpn-secret" = {
          file = ../../secrets/check24-janbaer.ovpn.age;
          path = "/home/${username}/.config/check24/check24-janbaer.ovpn";
          owner = "${username}";
          mode = "0600";
          symlink = false;
        };
        "check24-bu-vpn-secrect" = {
          file = ../../secrets/check24-bu-vpn.ovpn.age;
          path = "/home/${username}/.config/check24/check24-bu-vpn.ovpn";
          owner = "${username}";
          mode = "0600";
          symlink = false;
        };
        "check24-janbaer-sshkey-secret" = {
          file = ../../secrets/check24-janbaer-sshkey.age;
          path = "/home/${username}/.ssh/id_ed25519-sk";
          owner = "${username}";
          mode = "0600";
          symlink = false;
        };
      };
    };

    system.activationScripts.script.text = ''
      #!/usr/bin/env bash
      if ! /run/current-system/sw/bin/nmcli connection show | grep -q "check24-bu-vpn"; then
        echo "CHECK24-BU-VPN connection not found. Importing configuration..."
        /run/current-system/sw/bin/nmcli connection import type openvpn file /home/${username}/.config/check24/check24-bu.ovpn
      else
        echo "CHECK24-BU-VPN connection already exists."
      fi
    '';

    programs.openvpn3.enable = true;

    environment.systemPackages = with pkgs; [
      c24VPNConnect
      c24VPNDisconnect
    ];
  };

}
