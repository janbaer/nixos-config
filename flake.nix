{
  description = "A simple NixOS flake";

  inputs = {
    # NixOS official package source, using the nixos-24.11 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: let 
    username = "jan";
    # configuration = { pkgs, ... }: {
    #   nixpkgs.overlays = [
    #     nix-vscode-extensions.overlays.default
    #   ];
    # };
  in {
    nixosConfigurations = {
      jabasoft-vm-nixos-02 = nixpkgs.lib.nixosSystem {
	system = "x86_64-linux";
	modules = [
	  ./configuration.nix 
	  {
	     _module.args = {
	       inherit username;
	     };
	  }
	  home-manager.nixosModules.home-manager
	  {
	    home-manager.useGlobalPkgs = true;
	    home-manager.useUserPackages = true;
	    home-manager.extraSpecialArgs = {
	      inherit username;
	    };

	    home-manager.users.${username} = import ./home.nix;
	  }
	];
       };
    };
  };
}
