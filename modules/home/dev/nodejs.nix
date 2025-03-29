{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.modules.dev.nodejs;
in
{
  options.modules.dev.nodejs.enable = mkEnableOption "NodeJS with global packages";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # nodejs -> Will be installed with Neovim
      typescript
    ];
  };
}

