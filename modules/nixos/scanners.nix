{ config, lib, pkgs, ... }:
with lib;
let 
  cfg = config.modules.printing;
in {
  options.modules.scanners.enable =
    mkEnableOption "Configuration for using scanners";

  config = mkIf cfg.enable {
    # https://wiki.nixos.org/wiki/Scanners
    hardware.sane.enable = true; # enables support for SANE scanners
  };
}
