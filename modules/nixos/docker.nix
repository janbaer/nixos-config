{ config, lib, pkgs, username, ... }:
with lib;
let
  cfg = config.modules.docker;
in {
  options.modules.docker.enable = mkEnableOption "Configuration of Docker/Podman";

  config = mkIf cfg.enable {
    # Enable common container config files in /etc/containers
    virtualisation.containers.enable = true;
    virtualisation = {
      podman = {
        enable = true;
        # Create a `docker` alias for podman, to use it as a drop-in replacement
        dockerCompat = true;
        # Required for containers under podman-compose to be able to talk to each other.
        defaultNetwork.settings.dns_enabled = true;
      };
    };

    users.users."${username}" = {
      isNormalUser = true;
      extraGroups = [ "podman" ];
    };
  };
}
