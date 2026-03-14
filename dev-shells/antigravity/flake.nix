{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixpkgs-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-master,
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
        master = import nixpkgs-master {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        default = pkgs.mkShellNoCC {
          buildInputs = [
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
