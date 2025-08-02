{ config
, lib
, pkgs
, username
, ...
}:
with lib; let
  cfg = config.modules.dev.claude;
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{
  options.modules.dev.claude.enable = mkEnableOption "Claude-code";

  config = mkIf cfg.enable {
    home.file = {
      ".claude/.keep".text = "";
    };

    home.shellAliases = {
      c = "claude --dangerously-skip-permissions";
      claude-update = "volta install @anthropic-ai/claude-code";
      clp = "claude -p --mcp-config '{\"mcpServers\":{\"context7\":{\"command\":\"npx\",\"args\":[\"@context7/mcp-server\"]}}}'";
    };

  home.file = {
    ".claude/commands/commit.md".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.claude/commands/commit.md";
    ".claude/commands/reload.md".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.claude/commands/reload.md";
    ".claude/hooks/task-complete-notify.sh".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.claude/hooks/task-complete-notify.sh";
    ".claude/settings.json".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.claude/settings.json";
    ".claude/rules.md".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.claude/rules.md";
    ".claude/memory-mcp.md".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.claude/memory-mcp.md";
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
