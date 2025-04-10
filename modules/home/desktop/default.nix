{ pkgs, ...}: {
  imports = [
    ./browsers.nix
    ./hyprland
  ];

  home.packages = with pkgs; [
    keepassxc
    obsidian
  ];
}
