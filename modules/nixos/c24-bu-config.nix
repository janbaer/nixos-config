{ config, lib, pkgs, hostname, username, ... }:
with lib;
let
  cfg = config.modules.c24-bu-config;
  
  caFile = (builtins.readFile ./files/c24-bu-localhost-selfsigned-ca.pem);

  # rsyncExcludesRemoteFile = pkgs.writeText "rsync-excludes-remote" (builtins.readFile ./files/backup/rsync-excludes-remote);
in {
  options.modules.c24-bu-config.enable =
    mkEnableOption "Configuration specific for CHECK24 BU";

  config = mkIf cfg.enable {
    security.pki.certificates =[
      ''
      ${caFile}
      ''
    ];
  };
}

