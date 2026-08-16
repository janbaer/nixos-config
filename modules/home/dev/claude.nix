{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
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
  claudeRun = pkgs.writeShellScriptBin "claudeRun" ''
    #!/usr/bin/env zsh
    export OPENCVE_API_TOKEN="$(gopass show cloud/opencve/api-token)"
    export VIKUNJA_API_TOKEN="$(gopass show home/vikunja/vikunja-mcp)"
    export MAILBOX_ORG_USERNAME="jan.baer@mailbox.org"
    export MAILBOX_ORG_IMAP_PASSWORD="$(gopass show mailbox.org/imap-mcp)"
    export MAILBOX_ORG_CALDAV_PASSWORD="$(gopass show mailbox.org/caldav-mcp)"
    claude "$@"
  '';
  openRouterClaude = pkgs.writeShellScriptBin "openRouterClaude" ''
    #!/usr/bin/env zsh
    export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
    export ANTHROPIC_AUTH_TOKEN="$(gopass show cloud/openrouter/claude-router)"
    export ANTHROPIC_API_KEY=""

    export ANTHROPIC_DEFAULT_SONNET_MODEL="google/gemini-3.7-flash"
    export ANTHROPIC_DEFAULT_OPUS_MODEL="moonshotai/kimi-k3"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek/deepseek-v4-flash-latest"

    if [ -f "$HOME/.claude/openrouter.env" ]; then
      echo "Using openrouter.env..."
      set -a
      source "$HOME/.claude/openrouter.env"
      set +a
    fi

    claude --dangerously-skip-permissions "$@"
  '';
in
{
  options.modules.dev.claude.enable = mkEnableOption "Claude-code";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      claudeInstall
      claudeRun
      openRouterClaude
      sox # Required for the Claude voice mode
    ];

    home.file = {
      ".claude/.keep".text = "";
    };

    home.shellAliases = {
      c = "claudeRun --dangerously-skip-permissions";
      clp = "claude -p --mcp-config '{\"mcpServers\":{\"context7\":{\"command\":\"npx\",\"args\":[\"@context7/mcp-server\"]}}}'";
      orc = "openRouterClaude";
      openspec-update = "mise upgrade npm:@fission-ai/openspec";
    };

    home.file = {
      ".claude/CLAUDE.md" = {
        source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.claude/CLAUDE.md";
        force = true;
      };
      ".claude/ABOUTME.md" = {
        source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.claude/ABOUTME.md";
        force = true;
      };

      ".claude/agents" = {
        source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.claude/agents";
        force = true;
      };
      ".claude/commands" = {
        source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.claude/commands";
        force = true;
      };
      ".claude/knowledge-base" = {
        source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.claude/knowledge-base";
        force = true;
      };
      ".claude/output-styles" = {
        source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.claude/output-styles";
        force = true;
      };
      ".claude/rules" = {
        source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.claude/rules";
        force = true;
      };
      ".claude/skills" = {
        source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.claude/skills";
        force = true;
      };

      # Projektweite MCP-Server für alles unter ~/Projects. Benutzername und
      # Passwörter stehen dort nur als Platzhalter und werden von claudeRun
      # aus gopass in die Umgebung gelegt.
      "Projects/.mcp.json" = {
        source = ./files/claude/projects.mcp.json;
        force = true;
      };
    };

    home.sessionPath = [
      "$HOME/.local/bin"
    ];
  };
}
