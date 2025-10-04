{ pkgs, ...}: {
  imports = [
    ./browsers.nix
    ./thunderbird.nix
    ./hyprland
    ./veracrypt
  ];

  home.packages = with pkgs; [
    nautilus        # File manager for GNOME
    sushi           # Quick previewer for Nautilus
    simple-scan     # Simple scanning utility
    keepassxc       # Offline password manager with many features
    obsidian        # Powerful knowledge base that works on top of a local folder of plain text Markdown files
    localsend       # Open source cross-platform alternative to AirDrop
    gedit           # Former GNOME text editor
    gthumb          # Image browser and viewer for GNOME
    papers          # Gnome document viewer (This is the fork and successor of Evince)
    filezilla       # Graphical FTP, FTPS and SFTP client
    easytag         # View and edit tags for various audio files
    pdfarranger     # PDF document editor
  ];
}
