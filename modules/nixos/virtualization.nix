{ config, lib, pkgs, ... }:
with lib;
let cfg = config.modules.virtualization;
in {
  options.modules.virtualization.enable = mkEnableOption "Configuration of virtualization tools";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      virt-viewer
    ];
  };
}
