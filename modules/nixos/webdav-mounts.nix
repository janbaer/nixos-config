{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
let
  cfg = config.modules.webdav-mounts;

  mounts = {
    mailbox-drive = "https://dav.mailbox.org/servlet/webdav.infostore/Userstore";
    seafile = "https://seafile.home.janbaer.de/seafdav/";
  };

  enabledMounts = filterAttrs (name: _: cfg.${name}.enable) mounts;
in
{
  options.modules.webdav-mounts = mapAttrs (name: _: {
    enable = mkEnableOption "WebDAV mount ${name} with davfs2";
  }) mounts;

  config = mkIf (enabledMounts != { }) {
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
          mapConf = pkgs.writeText "auto" (
            concatStrings (mapAttrsToList (name: url: "${name} -fstype=davfs,uid=1000 :${url}\n") enabledMounts)
          );
        in
        ''
          /home/${username}/mnt file:${mapConf}
        '';
    };
  };
}
