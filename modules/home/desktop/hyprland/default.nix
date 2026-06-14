{ config, inputs, lib, pkgs, hostname, ... }:
with lib; let
  cfg = config.modules.desktop.browsers;
  # Noctalia provides notifications; drop dunst where the shell is enabled.
  noctaliaEnabled = config.modules.desktop.noctalia.enable;
in
{
  imports = [
    ./hyprland.nix
    ./hypr-window-switcher.nix
    ./hyprlock.nix
    ./noctalia.nix
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
      feh                             # Selecting Images for the wallpaper
      xdg-desktop-portal-hyprland     # xdg-desktop-portal backend for hyprland
      wl-clipboard                    # Handling system-wide clipboard in Wayland
      cliphist                        # The new clipboard manager
      grim                            # Required for making screenshots
      slurp                           # Required for making screenshots
      swappy                          # Required for making screenshots
      yad                             # Show a GTK popup from the commandline
      imagemagick                     # Software suite to create, edit, compose, or convert bitmap images
      nsxiv                           # New Suckless X Image Viewer
      # network-manager-applet
      playerctl                       # Command-line utility and library for controlling media players that implement MPRIS
      volumeicon
      brightnessctl                   # Control monitor brightness with fn-keys
      wdisplays                       # Configuring display in Wayland
      dconf
      gsettings-desktop-schemas
    ]
    ++ lib.optionals (!noctaliaEnabled) [
      dunst                           # Show user messages (replaced by Noctalia)
      pasystray                       # PulseAudio tray applet (replaced by Noctalia's Volume widget)
    ];

    home.shellAliases = {
      copy = "wl-copy";
    };

    services = {
      # Noctalia's Network widget replaces nm-applet's tray icon.
      network-manager-applet.enable = !noctaliaEnabled;
      mpris-proxy.enable = true;             # enable a proxy forwarding Bluetooth MIDI controls via MPRIS2 to control media players
    };

    systemd.user.targets.hyprland-session.Unit.Wants = [
      "xdg-desktop-autostart.target"
    ];

    home.file = {
      ".config/swappy/config".source = ./swappy/config;
      ".config/rofi".source = ./rofi;
      # hyprpaper (hyprlang) does not expand $HOME, so bake the absolute path in.
      # hyprpaper 0.8 (NixOS 26.05) replaced the flat preload/wallpaper lines with
      # a wallpaper {} block; empty monitor applies to all outputs.
      ".config/hypr/hyprpaper.conf".text = ''
        wallpaper {
            monitor =
            path = ${config.home.homeDirectory}/.wallpaper.jpg
        }
      '';
      ".config/nsxiv/exec/key-handler".source = ./nsxiv/exec/key-handler;
    }
    // lib.optionalAttrs (!noctaliaEnabled) {
      ".config/dunst/dunstrc".source = ./dunst/dunstrc;
    };
  };
}

