{ config, pkgs, username, ... }:
let
  inherit
    (import ./variables.nix)
    useHyprland
    ;
in
{
  imports = [
    ./../../modules/home
  ];

  modules = {
    dev = {
      nodejs.enable = true;
      golang.enable = true;
      rust.enable = true;
      vscode.enable = true;
      python.enable = true;
      k8s-cli.enable = true;
      claude.enable = true;
      zed-editor.enable = true;
      goose-cli.enable = true;
    };
    desktop = {
      hyprland.enable = useHyprland;
      browsers.enable = true;
      thunderbird.enable = true;
      veracrypt.enable = true;
    };
    shell = {
      gopass.enable = true;
      moc.enable = true;
    };
    gpg.enable = true;
  };

  home.username = username;
  home.homeDirectory = "/home/${username}";

  # link the configuration file in current directory to the specified location in home directory
  # home.file.".config/i3/wallpaper.jpg".source = ./wallpaper.jpg;

  # link all files in `./scripts` to `~/.config/i3/scripts`
  # home.file.".config/i3/scripts" = {
  #   source = ./scripts;
  #   recursive = true;   # link recursively
  #   executable = true;  # make all files executable
  # };

  # encode the file content in nix configuration file directly
  # home.file.".xxx".text = ''
  #     xxx
  # '';

  # set cursor size and dpi for 4k monitor
  xresources.properties = {
    "Xcursor.size" = 18;
    "Xft.dpi" = 172;
  };

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "24.11";

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
