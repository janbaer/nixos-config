{pkgs, ...}: {
  imports = [
    ./cli.nix
    ./dev
    ./desktop
    ./dotfiles.nix
  ];
}

