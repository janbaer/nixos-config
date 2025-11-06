{ config
, lib
, pkgs
, ...
}:
with lib; let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  cfg = config.modules.dev.claude;

  claudeInstall = pkgs.writeShellScriptBin "claudeInstall" ''
    #!/usr/bin/env bash

    if [ -f "$HOME/.local/bin/claude" ]; then
      echo "Claude-code is already installed"
      exit 0;
    fi
    echo "Installing claude-code..."
    ${pkgs.curl}/bin/curl -fsSL https://claude.ai/install.sh |${pkgs.bash}/bin/bash
  '';
in
{
  options.modules.dev.claude.enable = mkEnableOption "Claude-code";

  config = mkIf cfg.enable {
    home.packages = [
      claudeInstall
    ];

    home.file = {
      ".claude/.keep".text = "";
    };

    home.shellAliases = {
      c = "claude --dangerously-skip-permissions";
      claude-update = "claude update";
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

    home.sessionPath = [
      "$HOME/.local/bin"
    ];
  };
}
