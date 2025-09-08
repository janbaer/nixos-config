{ config, lib, pkgs, hostname, ... }:
with lib;
let
  inherit
    (import ./../../hosts/${hostname}/variables.nix)
    sshMatchBlocks
    ;
in {
  home.file = {
    ".ssh/id_ed25519.pub".text = builtins.readFile ./../../secrets/id_ed25519.pub;
    ".ssh/id_ed25519_jabasoft-ug.pub".text = builtins.readFile ./../../secrets/id_ed25519_jabasoft-ug.pub;
  };

  programs.ssh = {
    enable = true;

    # Global SSH settings
    extraConfig = ''
      StrictHostKeyChecking yes
      ServerAliveInterval 60
      IdentityAgent /run/user/1000/gnupg/S.gpg-agent.ssh
    '';

    matchBlocks = {
      "github.com" = {
        user = "janbaer";
      };
      "forgejo" = {
        port = 2222;
      };
    } // sshMatchBlocks;
  };
}
