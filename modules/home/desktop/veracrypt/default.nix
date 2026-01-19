{ config, lib, pkgs, username, ... }:
with lib;
let cfg = config.modules.desktop.veracrypt;
in {
  options.modules.desktop.veracrypt.enable = mkEnableOption "Install Veracrypt";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ veracrypt ];
  };
}
