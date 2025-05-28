{ config, lib, pkgs, username, ... }:
with lib;
let cfg = config.modules.desktop.veracrypt;
in {
  options.modules.desktop.veracrypt.enable = mkEnableOption "Install Veracrypt";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ veracrypt ];

    home.file = {
      "bin/mount-mydocuments.sh".source = ./files/mount-mydocuments.sh;
      "bin/mount-mynotes.sh".source = ./files/mount-mynotes.sh;
      "bin/mount-backup.sh".source = ./files/mount-backup.sh;
      "bin/mount-transfer.sh".source = ./files/mount-transfer.sh;
      "bin/unmount-mydocuments.sh".source = ./files/unmount-mydocuments.sh;
      "bin/unmount-mynotes.sh".source = ./files/unmount-mynotes.sh;
      "bin/unmount-backup.sh".source = ./files/unmount-backup.sh;
      "bin/unmount-transfer.sh".source = ./files/unmount-transfer.sh;
      "bin/mount-xxx.sh".source = ./files/mount-xxx.sh;
      "bin/mount-xxx-kg.sh".source = ./files/mount-xxx-kg.sh;
      "bin/unmount-xxx.sh".source = ./files/unmount-xxx.sh;
      "bin/unmount-xxx-kg.sh".source = ./files/unmount-xxx-kg.sh;
    };

    home.activation = {
      create_veracrypt_mount_dirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        user="${username}"
        dir_names="MyDocuments MyNotes XXX-KG"

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
