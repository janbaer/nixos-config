{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.modules.desktop.browsers;
in
{
  options.modules.desktop.browsers.enable = mkEnableOption "Install web browsers";

  config = mkIf cfg.enable {
    programs = {
      firefox.enable = true;
      chromium.enable = true;
    };
  };
}

