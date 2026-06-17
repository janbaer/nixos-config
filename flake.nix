{
  description = "Jans NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # Floated solely for noctalia-shell 4.7.7: 26.05 still ships 4.7.6, whose app
    # launcher uses plain `hyprctl dispatch exec` and breaks on our Lua-configured
    # Hyprland. 4.7.7 added the Lua-aware dispatch. Overlaid below; nothing else
    # is pulled from this input.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia/legacy-v4";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      agenix,
      ...
    }@inputs:
    let
      mkSystem =
        pkgs: system: hostname: username: userfullname:
        pkgs.lib.nixosSystem {
          specialArgs = {
            inherit system;
            inherit inputs;
            inherit username;
            inherit userfullname;
            inherit hostname;
          };
          modules = [
            ./hosts/${hostname}/configuration.nix
            {
              # Float only noctalia-shell (and its noctalia-qs dep, pulled
              # transitively) from nixos-unstable to get 4.7.7's Lua-aware dispatch.
              # Applied to every host in the flake; drop once nixos-26.05 ships
              # noctalia-shell >= 4.7.7 (verify with ./nixos-check-pkg-channels.sh).
              nixpkgs.overlays = [
                (final: prev: {
                  noctalia-shell = inputs.nixpkgs-unstable.legacyPackages.${system}.noctalia-shell;
                })
              ];
            }
            agenix.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                backupFileExtension = "hm-bak";
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {
                  inherit username;
                  inherit userfullname;
                  inherit hostname;
                  inherit inputs;
                  inherit system;
                };
                users.${username} = import ./hosts/${hostname}/home.nix;
                sharedModules = [
                  agenix.homeManagerModules.age
                ];
                verbose = false; # Enable verbose home-manager activation
              };
            }
          ];
        };
      pkgs = nixpkgs.legacyPackages."x86_64-linux";

      nhs = pkgs.writeShellScriptBin "nhs" "nh os switch .";
      nhb = pkgs.writeShellScriptBin "nhb" "nh os build .";
    in
    {
      nixosConfigurations = {
        jabasoft-tx = mkSystem nixpkgs "x86_64-linux" "jabasoft-tx" "jan" "Jan Baer";
        jabasoft-pc2 = mkSystem nixpkgs "x86_64-linux" "jabasoft-pc2" "jan" "Jan Baer";
        jabasoft-nixos-vm-01 = mkSystem nixpkgs "x86_64-linux" "jabasoft-nixos-vm-01" "jan" "Jan Baer";
      };

      devShells."x86_64-linux".default = pkgs.mkShell {
        packages = with pkgs; [
          nh
          nvd
          nixfmt
          nhs
          nhb
        ];
      };
    };
}
