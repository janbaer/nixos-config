{ config
, lib
, pkgs
, hostname
, ...
}:
with lib;
let
  inherit
    (import ./../../../hosts/${hostname}/variables.nix)
    globalNpmPackages
    ;
  cfg = config.modules.dev.nodejs;
  nodeInstall = pkgs.writeShellScriptBin "nodeInstall" ''
    #!/usr/bin/env bash
    
    echo "Checking and installing Node.js packages with volta..."

    if [ ! volta which node &>/dev/null ]; then
      echo "Node.js is not installed. Please install Node.js first."
      volta install node
    fi

    if [ -z "$GLOBAL_NPM_PACKAGES" ]; then
      echo "No global packages specified. Please specify the global packages to install."
      exit 1
    fi
    
    for package in $GLOBAL_NPM_PACKAGES; do
      echo "Installing $package..."
      volta install $package
      if [ $? -eq 0 ]; then
        echo "✓ Successfully installed $package"
      else
        echo "✗ Failed to install $package"
      fi
    done
  '';
in
{
  options.modules.dev.nodejs.enable = mkEnableOption "NodeJS with global packages";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      volta
      nodeInstall
    ];

    home.sessionVariables = {
      VOLTA_HOME = "$HOME/.volta";
      GLOBAL_NPM_PACKAGES = lib.concatStringsSep " " globalNpmPackages;
    };

    home.sessionPath = [
      "$HOME/.volta/bin"
    ];

    home.activation = {
      configure_volta = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p $HOME/.volta/bin
      '';
    };

    home.shellAliases = {
      y = "yarn";
      yi = "yarn install --pure-lockfile";
      yl = "yarn lint";
      ys = "yarn start";
      yt = "yarn test";
      ytw = "yarn test:watch";
      yui = "yarn upgrade-interactive --latest";
      yd = "yarn debug";
    };
  };
}

