{ config, lib, pkgs, hostname, ... }: let
  inherit
    (import ./../../../../hosts/${hostname}/variables.nix)
    useHyprland
    ;
  # Noctalia provides the power menu; drop wlogout where it is enabled.
  noctaliaEnabled = config.modules.desktop.noctalia.enable;
in
{
  programs.wlogout.enable = useHyprland && !noctaliaEnabled;
  home.file = {
    ".config/wlogout".source = ./wlogout;
  };
}
