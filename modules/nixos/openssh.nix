{ config, lib, pkgs, username, ... }:
with lib; let
  cfg = config.modules.openssh;
in
{
  options.modules.openssh.enable = mkEnableOption "Configuration for OpenSSH server";

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings = {
        AllowGroups = [ "ssh-users" ];
        KbdInteractiveAuthentication = false;
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        PrintMotd = true;
      };
      ports = [ 23 ];
      extraConfig = ''
      '';
    };
  };
}
