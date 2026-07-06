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
    version = "0.7.1";
    src = pkgs.fetchurl {
      url = "https://github.com/ogulcancelik/herdr/releases/download/v${version}/herdr-linux-x86_64";
      hash = "sha256-uWWsr/wsIvVLbmxkr3z46Yo/SsJiJjCgWZxnpLnYplQ=";
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

    # Seed the config once. We deliberately do NOT use xdg.configFile here:
    # that would symlink the file into the read-only Nix store, making it
    # impossible to edit at runtime. Instead we copy it on activation and
    # only if it does not already exist, so the user's edits are preserved.
    home.activation.herdrConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      configDir="${config.xdg.configHome}/herdr"
      configFile="$configDir/config.toml"
      if [ ! -e "$configFile" ]; then
        $DRY_RUN_CMD mkdir -p "$configDir"
        $DRY_RUN_CMD cp $VERBOSE_ARG ${./files/herdr/config.toml} "$configFile"
        $DRY_RUN_CMD chmod u+w "$configFile"
      fi
    '';
  };
}
