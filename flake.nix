{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    agenix.url = "github:ryantm/agenix";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , agenix
    , ...
    }@inputs:
    let
      username = "jan";
    in
    {
      nixosConfigurations = {
        jabasoft-vm-nixos-02 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/jabasoft-vm-nixos-02/configuration.nix
            {
              _module.args = {
                inherit inputs;
                inherit username;
              };
            }
            agenix.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit username;
              };
              home-manager.users.${username} = import ./home/${username}/home.nix;
              home-manager.sharedModules = [
              ];
            }
          ];
        };
      };
    };
}
