{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.modules.usb-automount;
in
{
  options.modules.usb-automount.enable = mkEnableOption "USB automount with udiskie";

  config = mkIf cfg.enable {
    services.udiskie = {
      enable = true;
      settings = {
        # workaround for
        # https://github.com/nix-community/home-manager/issues/632
        program_options = { file_manager = "${pkgs.nautilus}/bin/nautilus"; };
      };
    };
  };
}
