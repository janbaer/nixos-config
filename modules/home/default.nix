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

  # Start/restart changed user services during activation instead of waiting for
  # the next login, so newly-added services (e.g. the hypridle pre-sleep locker)
  # come up on `nixos-switch` without a relogin.
  systemd.user.startServices = "sd-switch";
}

