{ pkgs, ... }: {
  imports = [
    ./openssh.nix
    ./yubikey.nix
    ./mailbox-drive.nix
    ./network-hosts.nix
  ];
}
