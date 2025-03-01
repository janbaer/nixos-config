{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.features.desktop.browsers;
in
{
  options.features.desktop.browsers.enable = mkEnableOption "Install web browsers";

  config = mkIf cfg.enable {
    programs = {
      firefox.enable = true;
      chromium.enable = true;
    };
  };
}

