{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      version = "0.76.2";
      hash = "sha256-yG7YCGPxSBjtPwvqOZURqPChzcHKG7q63XAgdA8QfQA=";
      vendorHash = "sha256-qF280cc4PfdcVW37ddC6AmQp/FZfYrQFau8w3D2IAb0=";
      # hash = nixpkgs.lib.fakeHash;
      # vendorHash = nixpkgs.lib.fakeHash;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          trivy = pkgs.trivy.overrideAttrs (old: {
            inherit version vendorHash;
            doCheck = false;
            src = old.src.override {
              tag = "v${version}";
              name = "trivy-${version}-source";
              inherit hash;
            };
          });
        in
        {
          default = pkgs.mkShellNoCC {
            buildInputs = [ trivy pkgs.go_1_27 ];
            shellHook = ''
              [ -n "$PS1" ] && echo "Trivy ${version} ready"
            '';
          };
        }
      );
    };
}
