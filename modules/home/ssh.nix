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

    # Upstream directive names, not the camelCase aliases: `matchBlocks` is
    # deprecated since home-manager 26.05 and warns on every evaluation. The
    # attribute name carries the pattern, so a block no longer needs a separate
    # `host`. "*" stays last in the rendered file regardless of where it sits
    # here — the module pulls it out and appends it.
    settings = {
      "github.com" = {
        User = "janbaer";
      };
      "forgejo" = {
        Port = 2222;
      };
      "jabasoft-*" = {
        Port = sshPort;
      };
      "*" = {
        ForwardAgent = false;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveInterval = 60;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
      };
    } // sshMatchBlocks;
  };
}
