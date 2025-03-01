{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.features.dev.golang;
in
{
  options.features.dev.golang.enable = mkEnableOption "Go programming language";

  config = mkIf cfg.enable {
    
  };
}


