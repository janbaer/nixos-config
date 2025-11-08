{...}: {
  imports = [
    ./desktop
    ./dev
    ./dotfiles.nix
    ./gpg.nix
    ./onepassword.nix
    ./secrets.nix
    ./shell
    ./ssh.nix
    ./usb-automount.nix
  ];
}

