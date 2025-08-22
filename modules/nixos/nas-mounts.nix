{ config, lib, pkgs, username, ... }:
with lib;
let
  cfg = config.modules.nas-mounts;
  smb_mount_opts = [
    "x-systemd.automount"
    "noauto"
    "x-systemd.idle-timeout=60"
    "x-systemd.device-timeout=5s"
    "x-systemd.mount-timeout=5s"
    "rw" # Enable read-write mode
    "uid=1000" # Set ownership to your user ID
    "gid=100" # Set group ownership (usually 'users' group)
    "file_mode=0644" # File permissions
    "dir_mode=0755" # Directory permissions
    "vers=3.0"
    "credentials=/home/${username}/.config/.smb-secrets"
  ];
  nfs_mount_opts = [
    "x-systemd.automount"
    "noauto"
    "x-systemd.idle-timeout=60"
    "x-systemd.device-timeout=5s"
    "x-systemd.mount-timeout=5s"
    "nfsvers=4"
  ];
in {
  options.modules.nas-mounts.enable = mkEnableOption "Mounting NAS shares";

  config = mkIf cfg.enable {
    age = {
      secrets = {
        "smb-secrets" = {
          file = ../../secrets/smb-secrets.age;
          path = "/home/${username}/.config/.smb-secrets";
          owner = "${username}";
          mode = "0600";
          symlink = false;
        };
      };
    };

    environment.systemPackages = [ pkgs.cifs-utils ];

    fileSystems = {
      music = {
        enable = true;
        mountPoint = "/mnt/music";
        device = "//jabasoft-ug/music";
        fsType = "cifs";
        options = smb_mount_opts;
      };
      videos = {
        enable = true;
        mountPoint = "/mnt/videos";
        device = "//jabasoft-ug/video";
        fsType = "cifs";
        options = smb_mount_opts;
      };
      photos = {
        enable = true;
        mountPoint = "/mnt/photos";
        device = "//jabasoft-ug/photo";
        fsType = "cifs";
        options = smb_mount_opts;
      };
      daten = {
        enable = true;
        mountPoint = "/mnt/daten";
        device = "//jabasoft-ug/daten";
        fsType = "cifs";
        options = smb_mount_opts;
      };
      setup = {
        enable = true;
        mountPoint = "/mnt/setup";
        device = "//jabasoft-ug/setup";
        fsType = "cifs";
        options = smb_mount_opts;
      };
      xxx = {
        enable = true;
        mountPoint = "/mnt/xxx";
        device = "//jabasoft-ug/xxx";
        fsType = "cifs";
        options = smb_mount_opts;
      };
      pve-music = {
        enable = true;
        mountPoint = "/mnt/pve/music";
        device = "jabasoft-pve:/data/metube/mp3";
        fsType = "nfs";
        options = nfs_mount_opts;
      };
      pve3-data= {
        enable = true;
        mountPoint = "/mnt/pve3-data";
        device = "jabasoft-nixos-lxc-01.home.janbaer.de:/data";
        fsType = "nfs";
        options = nfs_mount_opts;
      };
    };
  };
}
