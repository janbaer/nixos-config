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
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-1.0.6.tgz";
      hash = "sha256-yMvx543OOClV/BSkM4/bzrbytL+98HAfp14Qk1m2le0=";
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
