{ config, lib, pkgs, username, ... }:
with lib;
let
  cfg = config.modules.openvpn;

  c24VPNConnect = pkgs.writeShellScriptBin "c24-openvpn-connect" ''
    #!/usr/bin/env bash
    profile="''${1:-c24}"
    if [ "$profile" = "c24" ]; then
      profile_path="/home/jan/.config/check24/c24-office-de.ovpn"
    else
      profile_path="/home/jan/.config/check24/c24-bu-openvpn-admin.ovpn"
    fi

    openvpn3 session-start --config "$profile_path"
  '';

  c24VPNDisconnect = pkgs.writeShellScriptBin "c24-openvpn-disconnect" ''
    #!/usr/bin/env bash
    openvpn3 sessions-list | grep "Path" | cut -d":" -f2 | cut -d ' ' -f2 | while read -r sessionpath; do
      openvpn3 session-manage --path "$sessionpath" --disconnect
    done
  '';
in {
  options.modules.openvpn.enable = mkEnableOption
    "Installation of OpenVPN3 and configurations related to CHECK24";

  config = mkIf cfg.enable {
    programs.openvpn3.enable = true;
    services.resolved.enable = true;

    environment.systemPackages = [ c24VPNConnect c24VPNDisconnect ];
  };
}
