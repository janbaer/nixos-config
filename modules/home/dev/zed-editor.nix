{ config, lib, pkgs, ... }:

with lib; let
  cfg = config.modules.dev.zed-editor;
in {
  options.modules.dev.zed-editor.enable = mkEnableOption "Zed editor";

  config = mkIf cfg.enable {
    home.packages = with pkgs;
      [
        zed-editor # High-performance, multiplayer code editor from the creators of Atom and Tree-sitter
      ];
  };
}
