{ config, lib, pkgs, hostname, ... }: let
  inherit
    (import ./../../../../hosts/${hostname}/variables.nix)
    useHyprland
    ;
in
{
  programs.rofi.enable = useHyprland;
  home.file = {
    ".config/rofi".source = ./rofi;
  };
}

