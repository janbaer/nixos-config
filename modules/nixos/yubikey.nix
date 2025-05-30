{ config, lib, pkgs, username, ... }:
with lib; let
  cfg = config.modules.yubikey;
in
{
  options.modules.yubikey.enable = mkEnableOption "Yubikey integration";

  config = mkIf cfg.enable {
    # See also https://nixos.wiki/wiki/Yubikey
    # https://joinemm.dev/blog/yubikey-nixos-guide

    services.udev.extraRules = ''
      # Key-ID FIDO U2F
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="096e", ATTRS{idProduct}=="0850|0880", TAG+="uaccess"

      # Yubico YubiKey
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0113|0114|0115|0116|0120|0200|0402|0403|0406|0407|0410", TAG+="uaccess", GROUP="plugdev", MODE="0660"
    '';

    age = {
      secrets = {
        "yubico-u2f-keys" = {
          file = ../../secrets/yubico-u2f-keys.age;
          path = "/home/${username}/.config/Yubico/u2f_keys";
          owner = "${username}";
          mode = "0600";
        };
      };
    };

    environment.systemPackages = with pkgs; [
      yubikey-personalization
      yubikey-manager
      yubioath-flutter
      yubico-pam
    ];

    services.pcscd.enable = true;

    security.pam = {
      services = {
        login.u2fAuth = true;
        sudo.u2fAuth = true;
      };
      u2f = {
        enable = true;
        control = "sufficient";
        settings = {
          interactive = false; # Prints a prompt first to insert the Yubikey (which is a bit annoying)
          pinverification = 1;
          cue = false; # Requires additionally to touch the Yubikey
        };
      };
      yubico = {
        enable = false;
        debug = true;
        control = "sufficient";
        mode = "challenge-response";
        id = [ "26724133" ];
      };
    };
  };
}

