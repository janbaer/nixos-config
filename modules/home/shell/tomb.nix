{ config, lib, pkgs, username, ... }:
with lib;
let
  cfg = config.modules.shell.tomb;

  tombOpen = pkgs.writeShellScriptBin "tombOpen" ''
    #!/usr/bin/env bash
    set -euo pipefail

    usage() {
      echo "Usage: $0 <name> <optional mount-dir>"
      echo "  name: Name of the tomb (without .tomb extension)"
      exit 1
    }

    if [[ $# -eq 0 ]]; then
      usage
    fi

    name="$1"

    base_dir="$(pwd)";
    tomb_file="$base_dir/''${name}.tomb"
    key_file="''${base_dir}/''${name}.tomb.key"
    tomb_pwd="$(gopass show "/home/tomb/''${name}")"

    mount_dir="''${2:-''${base_dir}}/''${name}"

    mkdir -p "$mount_dir"

    if [[ ! -f "$tomb_file" ]]; then
      echo "Error: Tomb file '$tomb_file' not found"
      exit 1
    fi

    if [[ ! -f "$key_file" ]]; then
      echo "Error: Key file '$key_file' not found"
      exit 1
    fi

    echo "Opening tomb '$tomb_file'..."
    tomb open "$tomb_file" "$mount_dir" -k "$key_file" --unsafe --tomb-pwd "$tomb_pwd"
  '';
  tombInit = pkgs.writeShellScriptBin "tombInit" ''
    #!/usr/bin/env bash
    set -euo pipefail

    usage() {
      echo "Usage: $0 <name> <size_in_gb>"
      echo "  name:       Name for the tomb file and key"
      echo "  size_in_gb: Size of the tomb in Gigabytes"
      exit 1
    }

    if [[ $# -ne 2 ]]; then
      usage
    fi

    name="$1"
    size_gb="$2"

    if ! [[ "$size_gb" =~ ^[0-9]+$ ]]; then
      echo "Error: Size must be a positive integer (in GB)"
      exit 1
    fi

    size_mb=$((size_gb * 1024))

    tomb_file="''${name}.tomb"
    key_file="''${name}.tomb.key"

    echo "Creating tomb '$tomb_file' with size ''${size_gb}GB (''${size_mb}MB)..."
    tomb dig -s "$size_mb" "$tomb_file"

    echo "Forging key '$key_file'..."
    tomb forge "$key_file"

    echo "Locking tomb with key..."
    tomb lock "$tomb_file" -k "$key_file"

    echo "Tomb '$tomb_file' created and locked successfully."
  '';
in {
  options.modules.shell.tomb.enable = mkEnableOption "Tomb encrypted storage";

  config = mkIf cfg.enable {
    home.file = {
      "bin/mount-mydocuments".source = ./files/tomb/mount-mydocuments.sh;
      "bin/unmount-mydocuments".source = ./files/tomb/unmount-mydocuments.sh;
      "bin/mount-mynotes".source = ./files/tomb/mount-mynotes.sh;
      "bin/unmount-mynotes".source = ./files/tomb/unmount-mynotes.sh;
      "bin/mount-xxx-kg".source = ./files/tomb/mount-xxx-kg.sh;
      "bin/unmount-xxx-kg".source = ./files/tomb/unmount-xxx-kg.sh;
      "bin/mount-xxx-susann".source = ./files/tomb/mount-xxx-susann.sh;
      "bin/unmount-xxx-susann".source = ./files/tomb/unmount-xxx-susann.sh;
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
    home.packages = with pkgs; [
      tomb
      tombInit
      tombOpen
    ];
  };
}
