{ config, pkgs, ... }:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{

  home.file = {
    "Projects/dotfiles" = {
      source = pkgs.fetchFromGitHub {
        owner = "janbaer";
        repo = "dotfiles";
        tag = "2025-03-01";
        sha256 = "uB7yxbYzvQsOKDNss1B/wqEzM9q+mTDA6WEao6aicKM=";
      };
      recursive = true;
    };
  };

  home.file = {
    ".config/lazygit".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.config/lazygit";
    ".config/nvim".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.config/nvim";
    ".config/atuin".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.config/atuin";
    ".p10k.zsh".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.p10k.zsh";
  };
}
