# Common configuration for all hosts
{ ... }: {

  boot.initrd.verbose = false; # Activate for verbose logging output (check with journalctl -b)

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

      # 26.05's mongodb-compass calls `wrapGAppsHook` from inside buildCommand,
      # where $output is not in scope — that variable only exists during
      # fixupPhase, which buildCommand replaces. The hook now guards against
      # double execution with an associative array keyed on $output, so the
      # empty subscript aborts the build with "bad array subscript". Upstream
      # fixed it the same way in nixos-unstable; drop this once 26.05 has the
      # backport (compare pkgs/by-name/mo/mongodb-compass/package.nix).
      (final: prev: {
        mongodb-compass = prev.mongodb-compass.overrideAttrs (old: {
          buildCommand =
            builtins.replaceStrings
              [ "wrapGAppsHook $out/bin/mongodb-compass" ]
              [ "gappsWrapperArgsHook\nwrapGApp \"$out/bin/mongodb-compass\"" ]
              old.buildCommand;
        });
      })
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
  };
}
