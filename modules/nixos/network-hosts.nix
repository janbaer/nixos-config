{ config, lib, pkgs, username, ... }:
with lib; let
  cfg = config.modules.network-hosts;
in
{
  options.modules.network-hosts.enable = mkEnableOption "Configuration of the hosts file";

  config = mkIf cfg.enable {
    networking = {
      hosts = {
        "192.168.20.3" = [ "jabasoft-pve" ];
        "192.168.20.7" = [ "forgejo" ];
      };
    };
  };
}

