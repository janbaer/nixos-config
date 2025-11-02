let
  jan = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINZlTGJF57sVlu7Prmm41Y8GmaqpespwCMFB7fLROBSm jan@janbaer.de";
  jabasoft-tx = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILg/cjVSovX0G9wtF9Ee4+Mb/G/Q53w+2sleHFmz6t99";
  jabasoft-pc2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBcDZI4YwQDYUINNCdySvhXQRwbPNt6h01oFICcfoqAh";
  jabasoft-nixos-vm-01 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGGJGCQJHN5V7fr0vM5N+9zGlAu5m7r404OWssz04zX6";
  agenix-home = "age1573nm8lhkuqpreukks33td6ur4kwyx2xp287nx7zup2qklp04dwq4e2awz";

  keys = [
    jan
    jabasoft-tx
    jabasoft-pc2
    jabasoft-nixos-vm-01
  ];

  home-keys = [ agenix-home ];

in {
  # This key will be used for the decryption of the keys that are used by the home-manager 
  "agenix-home-key.age".publicKeys = keys;

  # Keys used by NixOS on system-level
  "davfs2-secrets.age".publicKeys = keys;
  "yubico-u2f-keys.age".publicKeys = keys;
  "smb-jabasoft-ug-secrets.age".publicKeys = keys;
  "smb-jabasoft-zb-secrets.age".publicKeys = keys;
  "wg0-conf-jabasoft-tx.age".publicKeys = keys;

  # Keys used by the home-manager
  "atuin.age".publicKeys = home-keys;
  "gpg-key-private.age".publicKeys = home-keys;
  "id_ed25519.age".publicKeys = home-keys;
  "id_ed25519-hetzner-sb.age".publicKeys = home-keys;
  "id_ed25519-jabasoft-ug.age".publicKeys = home-keys;
  "zsh-secrets.age".publicKeys = home-keys;
}
