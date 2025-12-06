{ config, pkgs, inputs, hostname, ... }:
let
  inherit (import ./variables.nix) sshPort;
in
{
  imports =
    [
      ./hardware-configuration.nix
      ./../common
      ./../../modules/nixos
    ];

  modules = {
    docker.enable = false;
    mailbox-drive.enable = false;
    nas-mounts.enable = false;
    network-hosts.enable = true;
    openssh.enable = true;
    openvpn.enable = false;
    printing.enable = false;
    scanners.enable = false;
    secrets.enable = true;
    yubikey.enable = false;
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = hostname;
    networkmanager.enable = true;
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };  

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    neovim
    ghostty
    inputs.agenix.packages."${pkgs.stdenv.hostPlatform.system}".default
  ];

  services.qemuGuest.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ sshPort ];
  };

  system.stateVersion = "25.05";
}
