{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = with pkgs; mkShell {
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
    };
}
