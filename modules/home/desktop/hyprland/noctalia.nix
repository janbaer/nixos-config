{ config, lib, inputs, ... }:
with lib;
let
  cfg = config.modules.desktop.noctalia;
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  options.modules.desktop.noctalia.enable =
    mkEnableOption "Noctalia desktop shell (Quickshell, v4 stable line)";

  config = mkIf cfg.enable {
    programs.noctalia-shell.enable = true;
  };
}
