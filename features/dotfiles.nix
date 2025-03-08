{ config, pkgs, ... }:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{

  home.file = {
    ".config/lazygit".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.config/lazygit";
    ".config/nvim".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.config/nvim";
    ".config/atuin".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.config/atuin";
    ".p10k.zsh".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.p10k.zsh";
    ".config/zsh/.functions".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.config/zsh/.functions";
    ".fzf-init.zsh".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.fzf-init.zsh";
    "bin/init-keychain.sh".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/bin/init-keychain.sh";
  };
}
