{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      version = "0.70.0";
      hash = "sha256-xMj5xA/q3ekMW8k1aHCKa5hsYZSFShghOO5K6MnDCBo=";
      vendorHash = "sha256-VbkCDzSF8gHxXpzzNxtPVRqUn/4l0AVHNzlsOKmXNG8=";
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
