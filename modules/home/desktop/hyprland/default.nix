{ config, inputs, lib, pkgs, hostname, ... }:
with lib; let
  cfg = config.modules.desktop.browsers;
in
{
  imports = [
    ./hyprland.nix
    ./hypr-window-switcher.nix
    ./hyprlock.nix
    ./waybar.nix
    ./waylogout.nix
  ];

  options.modules.desktop.hyprland.enable = mkEnableOption "Install Hyprland with my prefered configuration";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      fira-code
      fira-code-symbols
      # nerd-fonts.fira-code
      # nerd-fonts.jetbrains-mono
      font-manager
      font-awesome_5
      noto-fonts

      hyprpaper                       # Show wallpapers in Hyprland
      hypridle
      rofi                            # A window switcher, application launcher and dmenu replacement
      dunst                           # Show user messages
      feh                             # Selecting Images for the wallpaper
      xdg-desktop-portal-hyprland     # xdg-desktop-portal backend for hyprland
      wl-clipboard                    # Handling system-wide clipboard in Wayland
      wayscriber                      # ZoomIt-like screen annotation tool for Wayland compositors, written in Rust
      cliphist                        # The new clipboard manager
      grim                            # Required for making screenshots
      slurp                           # Required for making screenshots
      swappy                          # Required for making screenshots
      yad                             # Show a GTK popup from the commandline
      blueman                         # Toolbar applet for Bluetooth
      imagemagick                     # Software suite to create, edit, compose, or convert bitmap images
      nsxiv                           # New Suckless X Image Viewer
      # network-manager-applet
      pasystray
      playerctl                       # Command-line utility and library for controlling media players that implement MPRIS
      volumeicon
      brightnessctl                   # Control monitor brightness with fn-keys
      wdisplays                       # Configuring display in Wayland
      dconf
      gsettings-desktop-schemas
    ];

    home.shellAliases = {
      copy = "wl-copy";
    };

    services = {
      network-manager-applet.enable = true;
      mpris-proxy.enable = true;             # enable a proxy forwarding Bluetooth MIDI controls via MPRIS2 to control media players
    };

    systemd.user.targets.hyprland-session.Unit.Wants = [
      "xdg-desktop-autostart.target"
    ];

    home.file = {
      ".config/swappy/config".source = ./swappy/config;
      ".config/rofi".source = ./rofi;
      ".config/hypr/hyprpaper.conf".source = ./hyprpaper/hyprpaper.conf;
      ".config/nsxiv/exec/key-handler".source = ./nsxiv/exec/key-handler;
      ".config/dunst/dunstrc".source = ./dunst/dunstrc;
    };
  };
}

