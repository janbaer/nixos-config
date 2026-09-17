{ config, lib, pkgs, username, ... }:
with lib; let
  cfg = config.modules.network-hosts;
in
{
  options.modules.network-hosts.enable = mkEnableOption "Configuration of the hosts file";

  config = mkIf cfg.enable {
    networking = {
      hosts = {
        "192.168.20.12" = [ "forgejo" ];
        "192.168.20.14" = [ "jabasoft-debian-vm-01.home.janbaer.de" ];
      };
    };
  };
}

