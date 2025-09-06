{ config, lib, pkgs, ... }:
let
  # https://flakehub.com/flake/sund3RRR/tuxedo-nixos?view=readme
  tuxedo = import (builtins.fetchTarball {
    url = "https://github.com/sund3RRR/tuxedo-nixos/archive/refs/tags/v1.0.1.tar.gz";
    sha256 = "sha256:136wb97skfbx20asc5b4zy8cxh6shs0bwys3nyac463s7yq59vhh";
  });
in
{
  imports = [
    tuxedo.outputs.nixosModules.default
  ];

  nixpkgs.overlays = [ tuxedo.outputs.overlays.default ];

  hardware.tuxedo-rs = {
    enable = true;
    tailor-gui.enable = true;
  };
  hardware.tuxedo-drivers.enable = true;
  hardware.tuxedo-control-center.enable = true;
}