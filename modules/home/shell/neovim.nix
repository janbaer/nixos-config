{ config, pkgs, ... }:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = false;
    sideloadInitLua = true;
  };

  home.sessionVariables = {
    # Fix the libsqlite.so not found issue for https://github.com/kkharji/sqlite.lua.
    # Important fix for the Telescope Neoclip plugin, which is using Sqlite3
    LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath (with pkgs; [ sqlite ])}:$LD_LIBRARY_PATH";
    EDITOR = "nvim";
  };

  home.shellAliases = {
    n = "nvim";
    vim = "nvim";
    nf = "nvim -O $(fzf -m --preview 'bat --color=always {}' --preview-window '~3')";
  };

  home.file = {
    ".config/nvim" = {
      source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/neovim-config/config";
      force = true;
    };
  };

  home.packages = with pkgs; [
    python312
    python312Packages.pip
    lua
    luarocks
    fd
    shfmt       # Shell formatter (honours .editorconfig)
    nixd        # LSP support for the Nix language
    tree-sitter # Syntax highlighting
  ];
}
