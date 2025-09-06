{pkgs, ...}: {
  imports = [
    ./shell
    ./dev
    ./desktop
    ./dotfiles.nix
    ./ssh.nix
    ./gpg.nix
    ./onepassword.nix
  ];
}

