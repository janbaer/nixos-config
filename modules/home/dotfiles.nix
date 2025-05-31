{ config, pkgs, lib, username, ... }:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{
  home.activation = {
    cloning_dotfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      dotfiles_dir=/home/${username}/Projects/dotfiles
      if [ ! -d "$dotfiles_dir" ]; then
        /run/current-system/sw/bin/git clone https://github.com/janbaer/dotfiles.git $dotfiles_dir
      fi
    '';
    cloning_wallpapers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      wallpapers_dir=/home/${username}/Pictures/wallpapers
      if [ ! -d "$wallpapers_dir" ]; then
        /run/current-system/sw/bin/git clone https://github.com/janbaer/wallpapers.git $wallpapers_dir
      fi
    '';
    copy_default_wallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] '' 
      cp ~/Pictures/wallpapers/wallhaven-wqery6.jpg ~/.wallpaper.jpg
    '';
  };

  home.file = {
    # ".config/lazygit".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.config/lazygit";
    ".config/nvim".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.config/nvim";
    ".p10k.zsh".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.p10k.zsh";
    ".config/zsh/.functions".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.config/zsh/.functions";
    ".fzf-init.zsh".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.fzf-init.zsh";
    "bin/init-keychain.sh".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/bin/init-keychain.sh";
    # ".gitconfig".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.gitconfig";
    ".gitconfig_check24".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.gitconfig_check24";
  };
}
