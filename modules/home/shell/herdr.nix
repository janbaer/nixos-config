{ config
, lib
, pkgs
, ...
}:
with lib;
let
  cfg = config.modules.shell.herdr;

  herdrBin = pkgs.stdenv.mkDerivation rec {
    pname = "herdr";
    version = "0.8.0";
    src = pkgs.fetchurl {
      url = "https://github.com/ogulcancelik/herdr/releases/download/v${version}/herdr-linux-x86_64";
      hash = "sha256-uHLqfkD6LLF+hXrJtisb8m23tAPGIvXS8/WzX26azSg=";
    };
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/herdr
      chmod +x $out/bin/herdr
    '';
  };
in
{
  options.modules.shell.herdr.enable = mkEnableOption "herdr CLI tool";

  config = mkIf cfg.enable {
    home.packages = [ herdrBin ];

    xdg.configFile."herdr/config.toml".source = ./files/herdr/config.toml;
  };
}
