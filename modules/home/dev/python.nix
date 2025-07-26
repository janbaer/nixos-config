{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.modules.dev.python;
in
{
  options.modules.dev.python.enable = mkEnableOption "Python related";

  config = mkIf cfg.enable {
    programs.go = {
      enable = true;
    };
    home.packages = with pkgs; [
      uv              # Extremely fast Python package installer and resolver, written in Rust
    ];

    home.sessionPath = [
      "$HOME/.local/share/../bin" # Required for tools installed with uv (uv tool install)
    ];
  };
}

