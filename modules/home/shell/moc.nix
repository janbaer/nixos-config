{ config, lib, pkgs, username, ... }:
with lib;
let cfg = config.modules.shell.moc;
in {
  options.modules.shell.moc.enable = mkEnableOption "Installs and configure the terminal media player moc";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ moc ];

    home.file = {
      ".moc/config".source = ./files/moc-config;
      ".moc/keymap".source = ./files/moc-keymap;
      ".moc/transparent-background".source = ./files/moc-transparent-background;
    };

    home.sessionVariables = {
      GOOD_SONGS_DIR = "$HOME/Music/good-songs";
    };
  };
}

