{ config, pkgs, ... }: {
  home.file = {
    ".ssh/id_ed25519.pub".text = builtins.readFile ./../../secrets/id_ed25519.pub;
    ".ssh/id_ed25519_jabasoft-ug.pub".text = builtins.readFile ./../../secrets/id_ed25519_jabasoft-ug.pub;
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        user = "janbaer";
      };
      "forgejo" = {
        port = 2222;
      };
    };
  };
}
