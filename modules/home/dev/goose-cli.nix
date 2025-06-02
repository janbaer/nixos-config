{ config, lib, pkgs, ... }:

with lib; let
  cfg = config.modules.dev.goose-cli; 
in {
  options.modules.dev.goose-cli.enable = mkEnableOption "goose-cli, Open-source, extensible AI agent";

  config = mkIf cfg.enable {
    home.packages = with pkgs;[
      goose-cli # Open-source, extensible AI agent that goes beyond code suggestions - install, execute, edit, and test with any LLM
    ];
  };
}
