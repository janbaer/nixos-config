{ config, lib, pkgs, username, ... }:
with lib; let
  cfg = config.features.dev.k8s-cli;
in
{
  options.features.dev.k8s-cli.enable = mkEnableOption "K8s developer tools";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      kubectl     # Communicate with K8s from the command line
      k9s         # TUI for managing K8s clusters and pods
      kubectx     # Switching between multips k8s servers (installs also kubens)
      stern       # Multi pod and container log tailing for Kubernetes
      helm        # Creating deployment charts
    ];
  };
}
