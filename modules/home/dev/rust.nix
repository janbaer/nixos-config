{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.modules.dev.rust;
in
{
  options.modules.dev.rust.enable = mkEnableOption "Rust programming language";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      cargo
      rustc
      rustfmt
    ];
  };
}

