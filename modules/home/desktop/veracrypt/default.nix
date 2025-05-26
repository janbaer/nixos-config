{ config, lib, pkgs, username, ... }:
with lib;
let cfg = config.modules.desktop.veracrypt;
in {
  options.modules.desktop.veracrypt.enable = mkEnableOption "Install Veracrypt";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ veracrypt ];

    home.file = {
      "bin/mount-mydocuments.sh".source = ./mount-mydocuments.sh;
      "bin/mount-mynotes.sh".source = ./mount-mynotes.sh;
      "bin/mount-backup.sh".source = ./mount-backup.sh;
      "bin/mount-transfer.sh".source = ./mount-transfer.sh;
      "bin/unmount-mydocuments.sh".source = ./unmount-mydocuments.sh;
      "bin/unmount-mynotes.sh".source = ./unmount-mynotes.sh;
      "bin/unmount-backup.sh".source = ./unmount-backup.sh;
      "bin/unmount-transfer.sh".source = ./unmount-transfer.sh;
    };

    home.activation = {
      create_veracrypt_mount_dirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        user="${username}"
        dir_names="MyDocuments MyNotes"

        mkdir -p $HOME/Secure
        chown $user $HOME/Secure
        chmod 0777 $HOME/Secure

        for dir in $dir_names; do
          if [ ! -d "$HOME/Secure/$dir" ]; then
            mkdir -p $HOME/Secure/$dir
            chown -R $user $HOME/Secure/$dir
            chmod 0777 $HOME/Secure/$dir
          fi
        done
      '';
    };
  };
}
