{ config, pkgs, lib, ... }:
let
  atuinLogin = pkgs.writeScriptBin "atuinLogin" ''
    #!/usr/bin/env bash
    if ${pkgs.atuin}/bin/atuin account verify &>/dev/null; then
     echo "Atuin account already verified, skipping login."
    else 
      source ${config.age.secrets.atuin.path}
      ${pkgs.atuin}/bin/atuin account login -u $ATUIN_USER -p $ATUIN_PASSWORD -k "$ATUIN_KEY"
      ${pkgs.atuin}/bin/atuin sync
    fi
  '';
in 
{
  age.secrets.atuin.file = ./../../../secrets/atuin.age;

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    flags = [
      "--disable-up-arrow"
    ];
  };

  home.file.".config/atuin/config.toml".source = ./files/atuin_config.toml;

  home.packages = [
    atuinLogin
  ];
}
