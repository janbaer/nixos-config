{ config, lib, pkgs, ... }:
with lib; let
  cfg = config.modules.dev.devops-tools;
in
{
  options.modules.dev.devops-tools.enable = mkEnableOption "DevOps tools like ansible and terraform";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      ansible
      terraform
    ];
    home.shellAliases = {
      tf = "terraform";
    };
  };
}
