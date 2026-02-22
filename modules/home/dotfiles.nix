{ config, pkgs, lib, username, ... }:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{
  home.activation = {
    cloning_dotfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      dotfiles_dir=/home/${username}/Projects/dotfiles
      if [ ! -d "$dotfiles_dir" ]; then
        ${pkgs.git}/bin/git clone https://github.com/janbaer/dotfiles.git $dotfiles_dir
      fi
    '';
    download_wallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      wallpaper_path=/home/${username}/.wallpaper.jpg
      if [ ! -f "$wallpaper_path" ]; then
        ${pkgs.curl}/bin/curl -o $wallpaper_path https://raw.githubusercontent.com/janbaer/wallpapers/refs/heads/main/wallhaven-wqery6.jpg
      fi
    '';
  };

  home.file = {
    ".config/nvim".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.config/nvim";
    ".p10k.zsh".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.p10k.zsh";
    ".config/zsh/.functions".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.config/zsh/.functions";
    ".fzf-init.zsh".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.fzf-init.zsh";
    "bin/close-ssh-connections.sh".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/bin/close-ssh-connections.sh";
    "bin/ntfy".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/bin/ntfy";
    ".gitconfig_check24".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.gitconfig_check24";
    ".editorconfig".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/.editorconfig";
  };
}
