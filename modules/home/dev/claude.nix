{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.modules.dev.claude;
  claude-code = pkgs.claude-code.overrideAttrs {
    version = "1.0.6";
    src = pkgs.fetchzip {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-1.0.24.tgz";
      hash = "sha256-1ci3l4l3xjr9xalmldi42d6zkwjc5p1nw04ccxlvnczj1syfnwsm";
    };
  };
in
{
  options.modules.dev.claude.enable = mkEnableOption "Claude-code";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      claude-code
    ];
  };
}
