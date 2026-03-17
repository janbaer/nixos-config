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
        version = "1.12.4";
        src = pkgs.fetchurl {
          url = "https://github.com/obsidianmd/obsidian-releases/releases/download/v${version}/obsidian-${version}.tar.gz";
          hash = "sha256-cusm388SP44HvoCD90+gRfQAxx7B/mTlirkdnMCEyN4=";
        };
      }))
    ];
  };
}
