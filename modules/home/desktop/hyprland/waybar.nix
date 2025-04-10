{ config, lib, pkgs, hostname, ... }: let
  inherit
    (import ./../../../../hosts/${hostname}/variables.nix)
    useHyprland
    ;
in
{
  programs.waybar.enable = useHyprland;
  home.file = {
    ".config/waybar".source = ./waybar;
  };
}
