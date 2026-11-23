{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.modules.dev.docker;
in
{
  options.modules.dev.docker.enable = mkEnableOption "Container image tools";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      skopeo
    ];

    home.file."bin/find-docker-image.sh" = {
      source = ./files/docker/find-docker-image.sh;
      executable = true;
    };
  };
}
