{pkgs, ...}: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = false;
    # nvim config is managed imperatively via the dotfiles symlink
    # (modules/home/dotfiles.nix), so don't let HM write its own init.lua
    # into ~/.config/nvim — load the provider config via wrapper args instead.
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
  };

  home.packages = with pkgs; [
    python312
    python312Packages.pip
    lua
    luarocks
    fd
    nixd        # LSP support for the Nix language
  ];
}
