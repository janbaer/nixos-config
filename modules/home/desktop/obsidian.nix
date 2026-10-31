{ config, lib, pkgs, inputs, system, ... }:
with lib;
let
  cfg = config.modules.desktop.obsidian;
  pinned = import inputs.nixpkgs-obsidian {
    inherit system;
    config.allowUnfree = true;
  };
in {
  options.modules.desktop.obsidian.enable =
    mkEnableOption "Install Obsidian knowledge base";

  config = mkIf cfg.enable {
    home.packages = [ pinned.obsidian ];
  };
}
