{ config, inputs, lib, pkgs, hostname, ... }:
with lib; let
  cfg = config.modules.desktop.browsers;
in
{
  imports = [
    ./hyprland.nix
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
      cliphist                        # The new clipboard manager
      grim                            # Required for making screenshots
      slurp                           # Required for making screenshots
      swappy                          # Required for making screenshots
      yad                             # Show a GTK popup from the commandline
      blueman                         # Toolbar applet for Bluetooth
      nsxiv                           # New Suckless X Image Viewer
      # network-manager-applet
      pasystray
      volumeicon
      brightnessctl                   # Control monitor brightness with fn-keys
      wdisplays                       # Configuring display in Wayland
    ];

    services.network-manager-applet.enable = true;

    systemd.user.targets.hyprland-session.Unit.Wants = [
      "xdg-desktop-autostart.target"
    ];

    home.file = {
      ".config/swappy/comfig".source = ./swappy/config;
      ".config/rofi".source = ./rofi;
      ".config/hypr/hyprpaper.conf".source = ./hyprpaper/hyprpaper.conf;
      ".config/nsxiv/exec/key-handler".source = ./nsxiv/exec/key-handler;
    };
  };
}

