{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.modules.dev.mongodb;
in
{
  options.modules.dev.mongodb.enable = mkEnableOption "MongoDB tools";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      mongodb-compass
    ];
  };
}

