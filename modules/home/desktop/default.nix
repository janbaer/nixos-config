{ pkgs, ...}: {
  imports = [
    ./browsers.nix
    ./obsidian.nix
    ./thunderbird.nix
    ./hyprland
  ];

  home.packages = with pkgs; [
    nautilus            # File manager for GNOME
    sushi               # Quick previewer for Nautilus
    simple-scan         # Simple scanning utility
    keepassxc           # Offline password manager with many features
    gedit               # Former GNOME text editor
    gthumb              # Image browser and viewer for GNOME
    gnome-disk-utility  # Udisks graphical front-end
    papers              # Gnome document viewer (This is the fork and successor of Evince)
    filezilla           # Graphical FTP, FTPS and SFTP client
    easytag             # View and edit tags for various audio files
    pdfarranger         # PDF document editor
    zathura             # Lightweight document viewer
  ];
}
