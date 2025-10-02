let
  jan = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINZlTGJF57sVlu7Prmm41Y8GmaqpespwCMFB7fLROBSm jan@janbaer.de";
  jabasoft-tx = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILg/cjVSovX0G9wtF9Ee4+Mb/G/Q53w+2sleHFmz6t99";
  jabasoft-pc2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBcDZI4YwQDYUINNCdySvhXQRwbPNt6h01oFICcfoqAh";
  jabasoft-nixos-vm-01 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGGJGCQJHN5V7fr0vM5N+9zGlAu5m7r404OWssz04zX6";
  
  keys = [
    jan 
    jabasoft-tx
    jabasoft-pc2
    jabasoft-nixos-vm-01
  ];
in {
  "zsh-secrets.age".publicKeys = keys;
  "id_ed25519.age".publicKeys = keys;
  "davfs2-secrets.age".publicKeys = keys;
  "yubico-u2f-keys.age".publicKeys = keys;
  "atuin.age".publicKeys = keys;
  "private-gpg-key.age".publicKeys = keys;
  "smb-jabasoft-ug-secrets.age".publicKeys = keys;
  "smb-jabasoft-zb-secrets.age".publicKeys = keys;
  "wg0-conf-jabasoft-tx.age".publicKeys = keys;
  "id_ed25519_jabasoft-ug.age".publicKeys = keys;
}
