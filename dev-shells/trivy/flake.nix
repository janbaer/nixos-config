{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      version = "0.74.0";
      hash = "sha256-OXOT8qwqh8Gy+IJcvBza5nai5bvNMcAMeeT+b2zuWDg=";
      vendorHash = "sha256-ajXgC6CCw0IaS/e3k0wGNIUOs9mTBIEuV21ZnwZj7SQ=";
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
