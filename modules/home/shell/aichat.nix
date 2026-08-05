{ config
, lib
, pkgs
, ...
}:
with lib;
let
  cfg = config.modules.shell.aichat;
in
{
  options.modules.shell.aichat.enable = mkEnableOption "aichat CLI AI assistant";

  config = mkIf cfg.enable {
    home.packages = [ pkgs.aichat ];

    home.shellAliases = {
      ai = "aichat \"$1\", give a short answer please";
    };

    xdg.configFile."aichat/config.yaml".text = ''
      ---
      model: openrouter:~deepseek/deepseek-v4-flash-latest
      clients:
        - type: openai-compatible
          name: openrouter
          api_base: https://openrouter.ai/api/v1
    '';
  };
}
