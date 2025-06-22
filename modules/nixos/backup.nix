{ config, lib, pkgs, hostname, username, ... }:
with lib;
let
  cfg = config.modules.backup;
  rsyncMyData = pkgs.writeShellScriptBin "rsync-mydata"
    (builtins.readFile ./files/backup/rsync-mydata.sh);

  rsyncExcludesRemoteFile = pkgs.writeText "rsync-excludes-remote" (builtins.readFile ./files/backup/rsync-excludes-remote);
in {
  options.modules.backup.enable =
    mkEnableOption "Configuration of backup with rsync to NAS and USB-drive";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ rsyncMyData ];

    systemd.timers."rsync-to-nas-timer" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
        AccuracySec = "15sec";
        Unit = "rsync-to-nas.service";
      };
    };

    systemd.services."rsync-to-nas" = {
      script = ''
        #!/usr/bin/env bash

        set -eu

        ${rsyncMyData}/bin/rsync-mydata \
        "jabasoft-ug" \
        "${hostname}" \
        "${username}" \
        "/home/${username}/" \ 
        "${rsyncExcludesRemoteFile}"
      '';
      path = with pkgs; [ rsync openssh ];
      serviceConfig = {
        Type = "oneshot";
        User = username;
      };
    };
  };
}
