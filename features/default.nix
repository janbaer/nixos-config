{pkgs, ...}: {
  imports = [
    ./shell
    ./dev
    ./desktop
    ./dotfiles.nix
  ];
}

