let
  commonVars = import ./../common/variables.nix;
in
commonVars // {
  # Host-specific overrides

  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIpVyTOS7SzGDYJNt5MnQA2/x3Wbzo2lrcHalwx6WqyT openpgp:0xED492215"
    "${builtins.readFile ./../../secrets/id_ed25519.pub}"
  ];
}
