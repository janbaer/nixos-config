{ config, pkgs, lib, username, ... }:
# let
#   atuinSecrets = builtins.fromTOML (builtins.readFile ./../../secrets/atuin.toml);
# in
{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
  };

  home.activation = {
    atuin_login = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      source /run/agenix/atuin
      /etc/profiles/per-user/${username}/bin/atuin login -u $ATUIN_USER -p $ATUIN_PASSWORD -k "$ATUIN_KEY"
    '';
  };

  home.file.".config/atuin/config.toml".source = ./files/atuin_config.toml;
}
