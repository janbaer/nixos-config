{ config, pkgs, username, ... }: {
  home.file = {
    ".ssh/id_ed25519.pub".text = builtins.readFile ./../../secrets/id_ed25519.pub;
    ".ssh/id_ed25519_forgejo.pub".text = builtins.readFile ./../../secrets/id_ed25519_forgejo.pub;
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
