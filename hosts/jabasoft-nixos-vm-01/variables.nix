let
  commonVars = import ./../common/variables.nix;
in
commonVars // {
  # Host-specific overrides

  # The GPG authentication subkey comes from common; the VM's own key is added.
  authorizedKeys = commonVars.authorizedKeys ++ [
    "${builtins.readFile ./../../secrets/id_ed25519.pub}"
  ];
}
