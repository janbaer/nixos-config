{ config, lib, pkgs, inputs, ... }:
with lib;
let
  cfg = config.modules.desktop.hermes-desktop;
  hermesDesktopBinPath = "${config.home.homeDirectory}/hermes-desktop/bin/hermes-desktop";
in {
  options.modules.desktop.hermes-desktop.enable = mkEnableOption "Hermes Agent desktop client";

  config = mkIf cfg.enable {
    home.shellAliases = {
      hermes-desktop = hermesDesktopBinPath;
    };

    xdg.desktopEntries.hermes-desktop = {
      name = "Hermes Desktop";
      genericName = "AI Agent Client";
      comment = "Native Electron client for the Hermes Agent gateway";
      exec = hermesDesktopBinPath;
      icon = pkgs.runCommand "hermes-desktop-icon.png" { } ''
        cp ${inputs.hermes-agent}/apps/desktop/assets/icon.png $out
      '';
      terminal = false;
      categories = [ "Network" "Utility" ];
    };
  };
}
