{ config
, lib
, pkgs
, ...
}:
with lib;
let
  cfg = config.modules.shell.tgpt;

  tgptBin = pkgs.stdenv.mkDerivation rec {
    pname = "tgpt";
    version = "2.11.1";
    src = pkgs.fetchurl {
      url = "https://github.com/aandrew-me/tgpt/releases/download/v${version}/tgpt-linux-amd64";
      hash = "sha256-mooB4mbYPM+tDwIOa2EiGrOCC9mMfsLf926XXIq9SGs=";
    };
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/tgpt
      chmod +x $out/bin/tgpt
    '';
  };
in
{
  options.modules.shell.tgpt.enable = mkEnableOption "tgpt CLI AI chat tool";

  config = mkIf cfg.enable {
    home.packages = [ tgptBin ];

    home.shellAliases = {
      tgpt = "tgpt --provider=gemini --model=gemini-3.1-flash-lite-preview --key=$GEMINI_API_KEY";
    };
  };
}
