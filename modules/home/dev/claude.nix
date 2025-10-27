{ config
, lib
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
      ".claude/skills".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.claude/skills";
    };
  };
}
