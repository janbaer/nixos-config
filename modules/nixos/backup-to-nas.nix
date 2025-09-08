{ config, lib, pkgs, hostname, username, ... }:
with lib;
let
  cfg = config.modules.backup-to-nas;
  rsyncMyData = pkgs.writeShellScriptBin "rsync-mydata"
    (builtins.readFile ./files/backup/rsync-mydata.sh);

  rsyncExcludesRemoteFile = pkgs.writeText "rsync-excludes-remote" (builtins.readFile ./files/backup/rsync-excludes-remote);
in {
  options.modules.backup-to-nas.enable =
    mkEnableOption "Configuration of backup with rsync to NAS and USB-drive";

  config = mkIf cfg.enable {
    environment.systemPackages = [ rsyncMyData ];

    systemd.timers."rsync-to-nas" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
        AccuracySec = "15sec";
        RandomizedDelaySec="5m";
        Unit = "rsync-to-nas.service";
      };
    };

    systemd.services."rsync-to-nas" = {
      script = ''
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
