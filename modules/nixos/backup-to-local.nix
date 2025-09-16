{ config, lib, pkgs, hostname, username, ... }:
with lib;
let
  cfg = config.modules.backup-to-local;
  rsyncMyData = pkgs.writeShellScriptBin "rsync-mydata"
    (builtins.readFile ./files/backup/rsync-mydata.sh);

  rsyncExcludesLocalFile = pkgs.writeText "rsync-excludes-remote" (builtins.readFile ./files/backup/rsync-excludes-local);
  rsyncExcludesMailboxDriveFile = pkgs.writeText "rsync-excludes-remote" (builtins.readFile ./files/backup/rsync-excludes-mailbox-drive);
in {
  options.modules.backup-to-local.enable =
    mkEnableOption "Configuration of backup with rsync to local USB-drive";

  config = mkIf cfg.enable {
    systemd.timers."rsync-to-local" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
        AccuracySec = "15sec";
        RandomizedDelaySec="5m";
        Unit = "rsync-to-local.service";
      };
    };

    systemd.services."rsync-to-local" = {
      script = ''
        ${rsyncMyData}/bin/rsync-mydata "USB" "${hostname}" "${username}" "/home/${username}/" "${rsyncExcludesLocalFile}"
      '';
      path = with pkgs; [ rsync openssh ];
      serviceConfig = {
        Type = "oneshot";
        User = username;
      };
    };
  };
}
