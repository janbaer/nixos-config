{pkgs, ...}: {
  imports = [
    ./cli.nix
    ./dev.nix
    ./desktop
  ];
}

