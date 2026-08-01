{
  config,
  lib,
  inputs,
  system,
  ...
}:
with lib;
let
  cfg = config.modules.dev.omp;
in
{
  options.modules.dev.omp.enable =
    mkEnableOption "omp (oh-my-pi), terminal coding agent with multi-model support";

  config = mkIf cfg.enable {
    home.packages = [ inputs.llm-agents.packages.${system}.omp ];
  };
}
