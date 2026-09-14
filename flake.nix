{
  description = "Jans NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
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
      # Only the home module is used; the package comes from nixpkgs. Keep the tag
      # in step with pkgs.noctalia so the module matches the installed version.
      # Check with: nix eval .#nixosConfigurations.<host>.pkgs.noctalia.version
      url = "github:noctalia-dev/noctalia/v5.0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Deliberately not following our nixpkgs: the uv2nix wheels are hashed
    # against the pinned one and a different tree breaks the build.
    hermes-agent.url = "github:NousResearch/hermes-agent";
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

      # The client only ever talks to the agent on agent.home.janbaer.de, so the
      # bundled one is 1.5 GB of closure and the two most expensive derivations
      # in the build for nothing. Stays out of the system generation on purpose:
      # build with `nix build .#hermes-desktop --out-link ~/hermes-desktop`.
      packages."x86_64-linux".hermes-desktop =
        inputs.hermes-agent.packages."x86_64-linux".desktop.override {
          hermesAgent = pkgs.writeShellScriptBin "hermes" ''
            echo "This client is built for remote use against agent.home.janbaer.de." >&2
            exit 1
          '';
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
