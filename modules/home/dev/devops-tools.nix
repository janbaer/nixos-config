{ config, lib, pkgs, ... }:
with lib; let
  cfg = config.modules.dev.devops-tools;
in {
  options.modules.dev.devops-tools.enable = mkEnableOption "DevOps tools like ansible and terraform";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      ansible       # Radically simple IT automation
      ansible-lint  # Best practices checker for Ansible
      terraform     # Tool for building, changing, and versioning infrastructure
      yamllint      # Linter for YAML files
    ];

    home.shellAliases = {
      tf = "terraform";
      agi = "ansible-galaxy install -r requirements.yml -f";
      mo = "molecule";
    };
  };
}
