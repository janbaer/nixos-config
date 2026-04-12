{ config, pkgs, hostname, ... }: 
let
  # Import the host-specific variables with defaults
  hostVariables = import (../../hosts/${hostname}/variables.nix);
  # Default to false if useTuxedo is not defined in variables.nix
  useTuxedo = hostVariables.useTuxedo or false;
in {
  imports = [
    ./backup-to-nas.nix
    ./backup-to-local.nix
    ./c24-bu-config.nix
    ./docker.nix
    ./localization.nix
    ./mailbox-drive.nix
    ./network-hosts.nix
    ./nas-mounts.nix
    ./openssh.nix
    ./openvpn.nix
    ./printing.nix
    ./scanners.nix
    ./secrets.nix
    ./users.nix
    ./tomb.nix
    ./virtualization.nix
    ./wireguard.nix
    ./yubikey.nix
  ] ++ (if useTuxedo then [ ./tuxedo-flake.nix ] else []);

  programs.zsh = {
    enable = true;
    enableCompletion = false;  # Home Manager handles compinit — avoid double init (~90ms saved)
    promptInit = "";           # p10k replaces the default prompt — skip prompt suse
  };
  environment.pathsToLink = [
    "/share/zsh"
  ];

  # Run unpatched dynamic binaries on NixOS 
  # https://github.com/nix-community/nix-ld
  # Helps to run Codeium: https://www.reddit.com/r/Codeium/comments/1cpnzra/for_anyone_on_nixos_if_codeium_doesnt_work/
  programs.nix-ld = {
    enable = true;
    libraries = [];
  };

  services.gnome = {
    sushi.enable = true;
  };
}
