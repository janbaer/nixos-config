{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      version = "0.73.0";
      hash = "sha256-+iJb/Eg97kjNzg6OTuEWXAPJ/32FpfVU2ED4/6A4U+I=";
      vendorHash = "sha256-0upMQ2fKKfaHAL/SVyzPpdRoBwMNS9PdHPHGAmEm148=";
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
            buildInputs = [ trivy ];
            shellHook = ''
              [ -n "$PS1" ] && echo "Trivy ${version} ready"
            '';
          };
        }
      );
    };
}
