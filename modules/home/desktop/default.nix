{ pkgs, ...}: {
  imports = [
    ./browsers.nix
  ];

  home.packages = with pkgs; [
    keepassxc
    obsidian
  ];
}
