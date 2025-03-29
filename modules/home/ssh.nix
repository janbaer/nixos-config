{ config, pkgs, username, ... }:

let 
  pubSshKey = builtins.readFile ./../../secrets/id_ed25519.pub;
  pubForgejoSshKey = builtins.readFile ./../../secrets/id_ed25519_forgejo.pub;
in
{
  home.file = {
    ".ssh/id_ed25519.pub".text = pubSshKey;
    ".ssh/id_ed25519_forgejo.pub".text = pubForgejoSshKey;
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "janbaer";
        identitiesOnly = true;
        identityFile = "~/.ssh/id_ed25519";
      };
      "forgejo" = {
        port = 2222;
        identitiesOnly = true;
        identityFile = "~/.ssh/id_ed25519_forgejo";
      };
    };
  };
}
