{ config, pkgs, hostname, ... }: {
  imports = [
    ./openssh.nix
    ./yubikey.nix
    ./mailbox-drive.nix
    ./network-hosts.nix
    ./users.nix
    ./nas-mounts.nix
    ./wireguard.nix
    ./docker.nix
    ./printing.nix
    ./scanners.nix
    ./backup.nix
    ./openvpn3.nix
  ] ++ (if (hostname == "jabasoft-tx") then [ ./tuxedo-flake.nix ] else []);

  programs.zsh.enable = true;
  # https://mynixos.com/home-manager/option/programs.zsh.enableCompletion
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
}
