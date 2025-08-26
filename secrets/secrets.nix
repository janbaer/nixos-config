let
  jan = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINZlTGJF57sVlu7Prmm41Y8GmaqpespwCMFB7fLROBSm jan@janbaer.de";
  jabasoft-vm-nixos-01 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHxJGNgX9h+fQK20Tmzqsj/l18sIA55NDoIZJEs57o5G";
  jabasoft-nb-01 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsLh7qXA/Hvo/ZEqa4F454Awr7ufHF2AXcUiFez30gz";
  jabasoft-tx = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILg/cjVSovX0G9wtF9Ee4+Mb/G/Q53w+2sleHFmz6t99";
  
  keys = [
    jan 
    jabasoft-vm-nixos-01 
    jabasoft-nb-01 
    jabasoft-tx
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
