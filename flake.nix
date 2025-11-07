{
  description = "Jans NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    hyprland.url = "github:hyprwm/Hyprland";
  };

  outputs =
    { 
      self
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
                backupFileExtension = "hm-bak";
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
                verbose = false;  # Enable verbose home-manager activation
              };
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        jabasoft-tx = mkSystem nixpkgs "x86_64-linux" "jabasoft-tx" "jan";
        jabasoft-pc2 = mkSystem nixpkgs "x86_64-linux" "jabasoft-pc2" "jan";
        jabasoft-nixos-vm-01 = mkSystem nixpkgs "x86_64-linux" "jabasoft-nixos-vm-01" "jan" ;
      };
    };
}
