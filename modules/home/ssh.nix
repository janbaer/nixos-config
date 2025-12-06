{ config, lib, pkgs, hostname, ... }:
with lib;
let
  inherit
    (import ./../../hosts/${hostname}/variables.nix)
    sshMatchBlocks
    sshPort
    ;
in {

  age.secrets = {
    "id_ed25519" = {
      file = ./../../secrets/id_ed25519.age;
      path = "${config.home.homeDirectory}/.ssh/id_ed25519";
      symlink = false;
    };
    "id_ed25519-hetzner-sb" = {
      file = ./../../secrets/id_ed25519-hetzner-sb.age;
      path = "${config.home.homeDirectory}/.ssh/id_ed25519-hetzner-sb";
      symlink = false;
    };
    "id_ed25519-jabasoft-ug" = {
      file = ./../../secrets/id_ed25519-jabasoft-ug.age;
      path = "${config.home.homeDirectory}/.ssh/id_ed25519-jabasoft-ug";
      symlink = false;
    };
  };

  home.file = {
    ".ssh/id_ed25519.pub".text = builtins.readFile ./../../secrets/id_ed25519.pub;
    ".ssh/id_ed25519-hetzner-sb.pub".text = builtins.readFile ./../../secrets/id_ed25519-hetzner-sb.pub;
    ".ssh/id_ed25519-jabasoft-ug.pub".text = builtins.readFile ./../../secrets/id_ed25519-jabasoft-ug.pub;
  };

  home.packages = with pkgs; [
    sshpass         # Non-interactive ssh password auth
  ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

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
      "jabasoft" = {
        host = "jabasoft-*";
        port = sshPort;
      };
      "*" = {
        forwardAgent = false;
        addKeysToAgent = "no";
        compression = false;
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
      };
    } // sshMatchBlocks;
  };
}
