{ config, lib, pkgs, hostname, ... }:
with lib;
let
  cfg = config.modules.desktop.obsidian;
in {
  options.modules.desktop.obsidian.enable =
    mkEnableOption "Install Obsidian knowledge base";

  config = mkIf cfg.enable {
    home.packages = [
      (pkgs.obsidian.overrideAttrs (_: rec {
        version = "1.12.7";
        src = pkgs.fetchurl {
          url = "https://github.com/obsidianmd/obsidian-releases/releases/download/v${version}/obsidian-${version}.tar.gz";
          hash = "sha256-/L4IsRHZwf2wm5wIlSsG4cgpxiFj66JYTEtOyFm+B50=";
        };
      }))
    ];
  };
}
