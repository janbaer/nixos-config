{ config, lib, pkgs, hostname, ... }:
with lib;
let
  cfg = config.modules.desktop.obsidian;
  vars = import ./../../../hosts/${hostname}/variables.nix;
in {
  options.modules.desktop.obsidian.enable =
    mkEnableOption "Install Obsidian knowledge base";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ obsidian ];

    home.sessionVariables = {
      OBSIDIAN_VAULT = vars.obsidianVault;
    };
  };
}
