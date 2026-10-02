{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      version = "0.75.0";
      hash = "sha256-z0QMnaHSoHR2eHFFWOFHn7EJV0QfQYSSTQ4Q7Q31QbQ=";
      vendorHash = "sha256-idc2wjjPVTRW9cImD/o40I+xdSzDwO7vEv2SB03FYl0=";
      # hash = nixpkgs.lib.fakeHash;
      # vendorHash = nixpkgs.lib.fakeHash;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          trivy = (pkgs.trivy.override {
            buildGoModule = pkgs.buildGoModule.override { go = pkgs.go_1_27; };
          }).overrideAttrs (old: {
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
