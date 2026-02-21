{
  config,
  lib,
  pkgs,
  ...
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
  openRouterClaude = pkgs.writeShellScriptBin "openRouterClaude" ''
    #!/usr/bin/env zsh
    export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
    export ANTHROPIC_AUTH_TOKEN="$(gopass show cloud/openrouter/claude-router)"
    export ANTHROPIC_API_KEY="" 

    export ANTHROPIC_DEFAULT_SONNET_MODEL="z-ai/glm-5.0"
    export ANTHROPIC_DEFAULT_OPUS_MODEL="moonshotai/kimi-k2.5"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="minimax/minimax-m2.5"

    claude --dangerously-skip-permissions "$@"
  '';
in {
  options.modules.dev.claude.enable = mkEnableOption "Claude-code";

  config = mkIf cfg.enable {
    home.packages = [
      claudeInstall
      openRouterClaude
    ];

    home.file = {
      ".claude/.keep".text = "";
    };

    home.shellAliases = {
      c = "claude --dangerously-skip-permissions";
      clp = "claude -p --mcp-config '{\"mcpServers\":{\"context7\":{\"command\":\"npx\",\"args\":[\"@context7/mcp-server\"]}}}'";
      orc = "openRouterClaude";
      openrouter-update = "volta install @fission-ai/openspec@latest";
    };

    home.file = {
      ".claude/hooks/task-complete-notify.sh".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.claude/hooks/task-complete-notify.sh";
      ".claude/settings.json".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.claude/settings.json";
      ".claude/memory-mcp.md".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.claude/memory-mcp.md";

      ".claude/commands".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.claude/commands";
      ".claude/skills".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.claude/skills";
      ".claude/rules".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.claude/rules";
      ".claude/knowledge-base".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.claude/knowledge-base";
    };

    home.sessionPath = [
      "$HOME/.local/bin"
    ];
  };
}
