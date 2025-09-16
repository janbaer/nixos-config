{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.modules.dev.golang;
in
{
  options.modules.dev.golang.enable = mkEnableOption "Go programming language";

  config = mkIf cfg.enable {
    programs.go = {
      enable = true;
    };

    home.packages = with pkgs; [
    ];
  };
}
