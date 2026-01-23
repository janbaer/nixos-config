{ pkgs, ...}: {
  imports = [
    ./browsers.nix
    ./thunderbird.nix
    ./hyprland
  ];

  home.packages = with pkgs; [
    nautilus            # File manager for GNOME
    sushi               # Quick previewer for Nautilus
    simple-scan         # Simple scanning utility
    keepassxc           # Offline password manager with many features
    obsidian            # Powerful knowledge base that works on top of a local folder of plain text Markdown files
    gedit               # Former GNOME text editor
    gthumb              # Image browser and viewer for GNOME
    gnome-disk-utility  # Udisks graphical front-end
    papers              # Gnome document viewer (This is the fork and successor of Evince)
    filezilla           # Graphical FTP, FTPS and SFTP client
    easytag             # View and edit tags for various audio files
    pdfarranger         # PDF document editor
    rquickshare         # Rust implementation of NearbyShare/QuickShare from Android for Linux
    zathura             # Lightweight document viewer
  ];
}
