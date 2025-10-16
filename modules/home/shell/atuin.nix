{ config, pkgs, lib, ... }:
{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    flags = [
      "--disable-up-arrow"
    ];
  };

  home.activation = {
    atuin_login = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if ${pkgs.atuin}/bin/atuin account verify &>/dev/null; then
        echo "Atuin account already verified, skipping login."
        exit 0
      fi
      source /run/agenix/atuin
      ${pkgs.atuin}/bin/atuin account login -u $ATUIN_USER -p $ATUIN_PASSWORD -k "$ATUIN_KEY"
    '';
  };

  home.file.".config/atuin/config.toml".source = ./files/atuin_config.toml;
}
