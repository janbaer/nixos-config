{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    agenix.url = "github:ryantm/agenix";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland";
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , agenix
    , ...
    }@inputs:
    let
      mkSystem = pkgs: system: hostname: username:
        pkgs.lib.nixosSystem
        {
          system = system;
          specialArgs = {
            inherit system;
            inherit inputs;
            inherit username;
            inherit hostname;
          };
          modules = [
            ./hosts/${hostname}/configuration.nix
            agenix.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {
                  inherit username;
                  inherit hostname;
                  inherit inputs;
                  inherit system;
                };
                users.${username} = import ./hosts/${hostname}/home.nix;
                sharedModules = [
                  agenix.homeManagerModules.age
                ];
              };
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        jabasoft-vm-nixos-02 = mkSystem inputs.nixpkgs "x86_64-linux" "jabasoft-vm-nixos-02" "jan" ;
        jabasoft-nb-01 = mkSystem inputs.nixpkgs "x86_64-linux" "jabasoft-nb-01" "jan";
      };
    };
}
