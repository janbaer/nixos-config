let
  commonVars = import ./../common/variables.nix;
in
commonVars // {
  # Host-specific overrides

  # Inherits the GPG authentication subkey from common instead of repeating it.
  # The list used to carry the CHECK24 Bitbucket subkey, which is what plain
  # `gpg --export-ssh-key` returns without the trailing "!".
  authorizedKeys = commonVars.authorizedKeys ++ [
    "${builtins.readFile ./../../secrets/id_ed25519.pub}"
  ];
}
