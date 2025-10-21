{ config, lib, hostname, ... }:
with lib;
let
  inherit
    (import ./../../hosts/${hostname}/variables.nix)
    sshPort;
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
      ports = [ sshPort ];
      openFirewall = true;
      extraConfig = ''
      '';
    };
  };
}
