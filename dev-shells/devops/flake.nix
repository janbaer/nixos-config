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
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          default = pkgs.mkShellNoCC {
            buildInputs = with pkgs; [
              ansible
              terraform
              lima
              molecule
              yamllint
              ansible-lint
            ];

            shellHook = ''
              echo "You're using Lima version: $(limactl --version)"
            '';
          };
        }
      );
    };
}

