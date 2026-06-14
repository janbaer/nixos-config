{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.modules.usb-automount;
  # Noctalia's SNI tray renders udiskie's icon as a broken placeholder; run it
  # tray-less there (automount keeps working) since Noctalia has no automount.
  noctaliaEnabled = config.modules.desktop.noctalia.enable;
in
{
  options.modules.usb-automount.enable = mkEnableOption "USB automount with udiskie";

  config = mkIf cfg.enable {
    services.udiskie = {
      enable = true;
      tray = mkIf noctaliaEnabled "never";
      settings = {
        # workaround for
        # https://github.com/nix-community/home-manager/issues/632
        program_options = { file_manager = "${pkgs.nautilus}/bin/nautilus"; };
      };
    };
  };
}
