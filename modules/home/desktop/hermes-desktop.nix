{ config, lib, pkgs, inputs, system, ... }:
with lib;
let
  cfg = config.modules.desktop.hermes-desktop;
in {
  options.modules.desktop.hermes-desktop.enable =
    mkEnableOption "Install the Hermes Agent desktop client (remote gateway GUI)";

  config = mkIf cfg.enable {
    home.packages = [
      inputs.hermes-agent.packages.${system}.desktop
    ];

    xdg.desktopEntries.hermes-desktop = {
      name = "Hermes Desktop";
      genericName = "AI Agent Client";
      comment = "Native Electron client for the Hermes Agent gateway";
      exec = "hermes-desktop";
      icon = pkgs.runCommand "hermes-desktop-icon.png" { } ''
        cp ${inputs.hermes-agent}/apps/desktop/assets/icon.png $out
      '';
      terminal = false;
      categories = [ "Network" "Utility" ];
    };
  };
}
