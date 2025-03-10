# Common configuration for all hosts
{ lib
, inputs
, outputs
, username
, ...
}: {
  imports = [
    ./secrets.nix
  ];

  system.activationScripts.userScript = {
    text = ''
      echo "Cloning dotfiles" > /var/log/nixos-rebuild-custom.log
      
      dotfiles_dir=/home/${username}/Projects/dotfiles
      if [ ! -d "$dotfiles_dir" ]; then
	/run/current-system/sw/bin/git clone https://github.com/janbaer/dotfiles.git $dotfiles_dir
      fi
      
      chown -R ${username}:users $dotfiles_dir
    '';
    deps = [];
  };

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      # outputs.overlays.additions
      # outputs.overlays.modifications
      # outputs.overlays.stable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [
        "root"
        "jan"
      ]; # Set users that are allowed to use the flake command
    };
    # Configure automatic cleanup and also garbage-collect of old generations
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };
    optimise.automatic = true;
    # registry =
    #   (lib.mapAttrs (_: flake: { inherit flake; }))
    #     ((lib.filterAttrs (_: lib.isType "flake")) inputs);
    # nixPath = ["/etc/nix/path"];
  };
}

