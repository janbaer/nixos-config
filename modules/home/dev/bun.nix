{ config
, lib
, pkgs
, ...
}:
with lib;
let
  cfg = config.modules.dev.bun;

  bunOverride = pkgs.bun.overrideAttrs (oldAttrs: rec {
    version = "1.4.5";
    src = builtins.fetchurl {
      url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
      sha256 = "sha256:1sv66qnb056jih5002kfs3byzwklxi641wpraaaa95c9a8xrnmcl";
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
