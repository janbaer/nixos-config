{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixpkgs-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    systems = ["x86_64-linux" "aarch64-darwin" "x86_64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    devShells = forAllSystems (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        master = import (builtins.fetchTarball {
          url = "https://github.com/NixOS/nixpkgs/archive/master.tar.gz";
          sha256 = "0lxsf4959s3c6azan30wzgbhnm3nnkh4mi13p2hw1r03a8cmwg0z";
        }) {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        default = pkgs.mkShellNoCC {
          buildInputs = with pkgs; [
            master.antigravity
          ];

          shellHook = ''
            antigravity
          '';
        };
      }
    );
  };
}
