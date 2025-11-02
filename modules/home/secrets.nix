{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.modules.secrets;
in
{
  options.modules.secrets.enable = mkEnableOption "User specific secrets management";

  config = mkIf cfg.enable {
    age.identityPaths = [ "/run/agenix/agenix-home-key" ];
  };
}

