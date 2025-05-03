{ pkgs, ...}: {
  imports = [
    ./browsers.nix
    ./hyprland
  ];

  home.packages = with pkgs; [
    nautilus
    simple-scan
    keepassxc
    obsidian
    localsend       # Open source cross-platform alternative to AirDrop
    gedit           # Former GNOME text editor
    gthumb          # Image browser and viewer for GNOME
    evince          # GNOME's document viewer
    filezilla       # Graphical FTP, FTPS and SFTP client
    seahorse        # Application for managing encryption keys and passwords in the GnomeKeyring

    easytag         # View and edit tags for various audio files
  ];
}
