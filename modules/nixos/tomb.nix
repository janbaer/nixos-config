{ config, lib, username, ... }:
with lib;
let
  cfg = config.modules.tomb;
in {
  options.modules.tomb.enable = mkEnableOption "Tomb encrypted storage system configuration";

  config = mkIf cfg.enable {
    # Extend sudo timeout to 60 minutes (default is 5 minutes)
    security.sudo.extraConfig = ''
      Defaults timestamp_timeout=60
    '';

    security.sudo.extraRules = [
      {
        users = [ username ];
        commands = [
          # Allow all mount operations
          {
            command = "/run/wrappers/bin/mount";
            options = [ "NOPASSWD" "SETENV" ];
          }
          {
            command = "/run/wrappers/bin/umount";
            options = [ "NOPASSWD" "SETENV" ];
          }
          # Allow losetup for loop device management
          {
            command = "/run/current-system/sw/bin/losetup";
            options = [ "NOPASSWD" "SETENV" ];
          }
          # Allow cryptsetup for LUKS operations
          {
            command = "/run/current-system/sw/bin/cryptsetup";
            options = [ "NOPASSWD" "SETENV" ];
          }
          # Allow tomb script itself
          {
            command = "/etc/profiles/per-user/${username}/bin/tomb";
            options = [ "NOPASSWD" "SETENV" ];
          }
        ];
      }
    ];

    # Polkit rules to allow loop device and cryptsetup operations without GUI prompts
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if ((action.id == "org.freedesktop.udisks2.loop-setup" ||
             action.id == "org.freedesktop.udisks2.encrypted-unlock" ||
             action.id == "org.freedesktop.udisks2.filesystem-mount") &&
            subject.user == "${username}") {
          return polkit.Result.YES;
        }
      });
    '';
  };
}
