{ config, lib, pkgs, ... }:
with lib; let
  cfg = config.modules.onepassword;
in
{
  options.modules.onepassword.enable = mkEnableOption "1Password desktop app and browser integration";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      _1password-cli
      _1password-gui
    ];
  };
}
