{ config
, lib
, pkgs
, username
, ...
}:
with lib; let
  cfg = config.modules.dev.claude;
in
{
  options.modules.dev.claude.enable = mkEnableOption "Claude-code";

  config = mkIf cfg.enable {
    home.file = {
      ".claude/.keep".text = "";
    };

    home.activation = {
      cloning_superclaude = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        superclaude_dir=/home/${username}/Projects/SuperClaude
        if [ ! -d "$superclaude_dir" ]; then
          ${pkgs.git}/bin/git clone https://github.com/SuperClaude-Org/SuperClaude_Framework.git $superclaude_dir
        else
          ${pkgs.git}/bin/git -C $superclaude_dir pull
        fi
      '';
      install_claude_usage_monitor = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if ! ${pkgs.uv}/bin/uv tool list | grep -q claude-usage-monitor; then
          ${pkgs.uv}/bin/uv tool install claude-usage-monitor
        fi
      '';
    };
  };
}
