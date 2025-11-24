{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    utils,
  }:
    utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};
      in {
        devShell = with pkgs;
          mkShell {
            buildInputs = [
              libiconv
              gcc
              cargo
              rustc
              rustfmt
              rustPackages.clippy
              rust-analyzer
            ];

            RUST_SRC_PATH = rustPlatform.rustLibSrc;

            shellHook = ''
              echo "Welcome to the Rust development shell, you are using $(rustc --version)"
            '';
          };
      }
    );
}
