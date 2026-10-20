{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.modules.dev.worktrunk;
in
{
  options.modules.dev.worktrunk.enable = mkEnableOption "worktrunk git worktree manager";

  config = mkIf cfg.enable {
    home.packages = [ pkgs.worktrunk ];

    home.file.".config/worktrunk/config.toml".source = ./files/worktrunk/config.toml;

    programs.zsh.initContent = ''
      eval "$(${pkgs.worktrunk}/bin/wt config shell init zsh)"
    '';
  };
}
