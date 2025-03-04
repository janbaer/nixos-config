let
  jabasoft-vm-nixos-01 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHxJGNgX9h+fQK20Tmzqsj/l18sIA55NDoIZJEs57o5G";
  jan = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINZlTGJF57sVlu7Prmm41Y8GmaqpespwCMFB7fLROBSm jan@janbaer.de";
  
  keys = [ jabasoft-vm-nixos-01 jan ];
in {
  "zsh-secrets.age".publicKeys = keys;
  "id_ed25519.age".publicKeys = keys;
}
