{ config, lib, pkgs, username, ... }:
with lib; let
  cfg = config.features.network-hosts;
in
{
  options.features.network-hosts.enable = mkEnableOption "Configuration of the hosts file";

  config = mkIf cfg.enable {
    networking = {
      hosts = {
        "192.168.178.7" = [ "forgejo" ];
      };
    };
  };
}

