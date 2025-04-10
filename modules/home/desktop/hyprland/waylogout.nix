{ config, lib, pkgs, hostname, ... }: let
  inherit
    (import ./../../../../hosts/${hostname}/variables.nix)
    useHyprland
    ;
in
{
  programs.wlogout.enable = useHyprland;
  home.file = {
    ".config/wlogout".source = ./wlogout;
  };
}
