{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.features.dev.rust;
in
{
  options.features.dev.rust.enable = mkEnableOption "Rust programming language";

  config = mkIf cfg.enable {
    
  };
}

