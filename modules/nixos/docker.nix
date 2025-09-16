{ config, lib, pkgs, username, ... }:
with lib;
let cfg = config.modules.docker;
in {
  options.modules.docker.enable =
    mkEnableOption "Configuration of Docker/Podman";

  config = mkIf cfg.enable {
    # Enable common container config files in /etc/containers
    virtualisation.containers.enable = true;
    virtualisation.containers.containersConf.settings = {
      network = {
        # Disable IPv6 for all container networks
        enable_ipv6 = false;
        pasta_options = ["--ipv4-only" "--no-ndp" "--no-dhcpv6" "--no-dhcp"];
      };
    };
    virtualisation = {
      podman = {
        enable = true;
        # Create a `docker` alias for podman, to use it as a drop-in replacement
        dockerCompat = true;
        # Required for containers under podman-compose to be able to talk to each other.
        defaultNetwork.settings = {
          dns_enabled = true;
          # Disable IPv6 for the default network
          ipv6_enabled = false;
        };
      };
    };

    users.users."${username}" = {
      isNormalUser = true;
      extraGroups = [ "podman" ];
    };
  };
}
