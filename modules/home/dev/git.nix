{ pkgs, ... }: {
  programs.lazygit = { enable = true; };

  home.shellAliases = {
    g = "git";
    gfp = "git fetch --prune && git pull";
  };
}
