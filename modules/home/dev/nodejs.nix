{ config
, lib
, pkgs
, ...
}:
with lib; let
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
      GLOBAL_NPM_PACKAGES = "typescript@5.8.3 prettier@3.5.3 eslint@9.28.0 yarn@1.22.22";
    };

    home.sessionPath = [
      "$HOME/.volta/bin"
    ];

    home.activation = {
      configure_volta = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p $HOME/.volta/bin
      '';
    };
  };
}

