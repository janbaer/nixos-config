{ config, lib, pkgs, username, ... }:
with lib; let
  cfg = config.modules.mailbox-drive;
in
{
  options.modules.mailbox-drive.enable = mkEnableOption "Mailbox.org Drive integration with davfs2";

  config = mkIf cfg.enable {
    age = {
      secrets = {
        "davfs2-secrets" = {
          file = ../../secrets/davfs2-secrets.age;
          path = "/etc/davfs2/secrets";
          mode = "0600";
        };
      };
    };

    services.davfs2 = {
      enable = true;
      settings = {
        globalSection = {
          # if\_match\_bug 1
          use_locks = false;
          cache_size = true;
          table_size = 4096;
          delay_upload = true;
          gui_optimize = true;
        };
      };
    };

    users.users.${username} = {
      extraGroups = [ "davfs2" ];
    };

    services.autofs = {
      enable = true;
      timeout = 600;
      autoMaster =
        let
          mapConf = pkgs.writeText "auto" ''
            mailbox-drive -fstype=davfs,conf=/etc/davfs2.conf,uid=1000 :https://dav.mailbox.org/servlet/webdav.infostore/Userstore
          '';
        in
        ''
          /home/${username}/mnt file:${mapConf}
        '';
    };
  };
}
