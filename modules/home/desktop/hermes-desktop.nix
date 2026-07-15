{ config, lib, inputs, system, ... }:
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
  };
}
