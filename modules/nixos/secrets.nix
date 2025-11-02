{ config, lib, username, ... }:
with lib;
let
  cfg = config.modules.secrets;
in
{
  options.modules.secrets.enable = mkEnableOption "System-level secrets management";

  config = mkIf cfg.enable {
    # Decrypt the age key for home-manager to use
    # This key will be used for the en- and decryption
    # of all other secrets
    age.secrets.agenix-home-key = {
      file = ../../secrets/agenix-home-key.age;
      mode = "0400";
      owner = username; # The file has to be owned by the user, otherwise home-manage has no access to it
    };
  };
}
