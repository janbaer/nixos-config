{ config, lib, pkgs, username, ... }:
with lib;
let
  cfg = config.modules.nas-mounts;

  # Data definitions
  smbServers = {
    jabasoft-ug = {
      host = "jabasoft-ug";
      shares = ["music" "video" "photo" "daten" "setup" "xxx"];
      credentialsFile = "smb-jabasoft-ug-secrets";
    };
    jabasoft-zb = {
      host = "jabasoft-zb.home.janbaer.de";
      shares = [{ name = "data"; mountPoint = "/mnt/zb-data"; }];
      credentialsFile = "smb-jabasoft-zb-secrets";
    };
  };

  nfsMounts = [
    {
      name = "pve3-data";
      mountPoint = "/mnt/pve3-data";
      device = "jabasoft-nixos-lxc-01.home.janbaer.de:/data";
    }
  ];

  # Helper functions
  mkSmbMountOpts = credentialsFile: [
    "x-systemd.automount"
    "noauto"
    "x-systemd.idle-timeout=60"
    "x-systemd.device-timeout=5s"
    "x-systemd.mount-timeout=5s"
    "rw"
    "uid=1000"
    "gid=100"
    "file_mode=0644"
    "dir_mode=0755"
    "vers=3.0"
    "credentials=/home/${username}/.config/.${credentialsFile}"
  ];

  mkNfsMountOpts = [
    "x-systemd.automount"
    "noauto"
    "x-systemd.idle-timeout=60"
    "x-systemd.device-timeout=5s"
    "x-systemd.mount-timeout=5s"
    "nfsvers=4"
  ];

  mkSmbMount = serverName: server: share:
    let
      shareName = if builtins.isString share then share else share.name;
      mountPoint = if builtins.isString share then "/mnt/${share}" else share.mountPoint;
    in
    nameValuePair shareName {
      enable = true;
      mountPoint = mountPoint;
      device = "//${server.host}/${shareName}";
      fsType = "cifs";
      options = mkSmbMountOpts server.credentialsFile;
    };

  mkNfsMount = mount:
    nameValuePair mount.name {
      enable = true;
      mountPoint = mount.mountPoint;
      device = mount.device;
      fsType = "nfs";
      options = mkNfsMountOpts;
    };

  # Generate all SMB mounts
  smbMounts = listToAttrs (flatten (
    mapAttrsToList (serverName: server:
      map (mkSmbMount serverName server) server.shares
    ) smbServers
  ));

  # Generate all NFS mounts
  nfsFileSystems = listToAttrs (map mkNfsMount nfsMounts);

  # Generate secrets for all SMB servers
  smbSecrets = listToAttrs (
    mapAttrsToList (serverName: server:
      nameValuePair server.credentialsFile {
        file = ../../secrets/${server.credentialsFile}.age;
        path = "/home/${username}/.config/.${server.credentialsFile}";
        owner = "${username}";
        mode = "0600";
        symlink = false;
      }
    ) smbServers
  );
in {
  options.modules.nas-mounts.enable = mkEnableOption "Mounting NAS shares";

  config = mkIf cfg.enable {
    age.secrets = smbSecrets;

    environment.systemPackages = [ pkgs.cifs-utils ];

    fileSystems = smbMounts // nfsFileSystems;
  };
}