{ config
, lib
, pkgs
, ...
}:
with lib;
let
  cfg = config.modules.dev.bun;

  bunOverride = pkgs.bun.overrideAttrs (oldAttrs: rec {
    version = "1.3.13";
    src = builtins.fetchurl {
      url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
      sha256 = "sha256:0np2g1x26lvc3k3if0zhwb89ksh7sgha058ywjm36b5rm0gpgh3r";
    };
  });
in
{
  options.modules.dev.bun.enable = mkEnableOption "Bun JavaScript runtime and toolkit";

  config = mkIf cfg.enable {
    home.packages = [
      bunOverride
    ];

    home.shellAliases = {
      b = "bun";
      bi = "bun install";
      br = "bun run";
      bt = "bun test";
      bx = "bunx";
      bd = "bun run dev";
      bb = "bun run build";
    };
  };
}
