{ pkgs, ... }: {
  imports = [
    ./openssh.nix
    ./yubikey.nix
    ./mailbox-drive.nix
    ./network-hosts.nix
    ./users.nix
    ./tuxedo.nix
  ];

  environment.variables = {
    EDITOR = "nvim";
  };

  environment.shellAliases = {
    n = "nvim";
    vim = "nvim";
    lsa = "ls -la";
  };

  programs.zsh.enable = true;
  # https://mynixos.com/home-manager/option/programs.zsh.enableCompletion
  environment.pathsToLink = [
    "/share/zsh"
  ];

  # Run unpatched dynamic binaries on NixOS 
  # https://github.com/nix-community/nix-ld
  # Helps to run Codeiumm: https://www.reddit.com/r/Codeium/comments/1cpnzra/for_anyone_on_nixos_if_codeium_doesnt_work/
  programs.nix-ld = {
    enable = true;
    libraries = [];
  };
}
