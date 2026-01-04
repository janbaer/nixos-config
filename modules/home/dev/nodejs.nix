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
    
    echo "Installing Node.js and global packages with volta..."
    ${pkgs.volta}/bin/volta install node

    if [ -z "$GLOBAL_NPM_PACKAGES" ]; then
      echo "No global packages specified. Please specify the global packages to install."
      exit 1
    fi
    
    for package in $GLOBAL_NPM_PACKAGES; do
      echo "Installing $package..."
      ${pkgs.volta}/bin/volta install $package
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

    home.shellAliases = {
      yi = "yarn install --pure-lockfile";
      yl = "yarn lint";
      ys = "yarn start";
      yt = "yarn test";
      ytw = "yarn test:watch";
      yui = "yarn upgrade-interactive --latest";
      yd = "yarn debug";
    };

    home.activation = {
      installing_nodejs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ -f "$HOME/.volta/bin/node" ]; then
          echo "Node.js and global packages already installed."
          exit 0;
        fi
        export GLOBAL_NPM_PACKAGES='${lib.concatStringsSep " " globalNpmPackages}'
        ${nodeInstall}/bin/nodeInstall
      '';
    };
  };
}

