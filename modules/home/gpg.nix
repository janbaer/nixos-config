{ config, lib, pkgs, hostname, username, ... }:
with lib;
let
  inherit
    (import ./../../hosts/${hostname}/variables.nix)
    gpgKey
    gpgSshKeys
    ;
  cfg = config.modules.gpg;
  keychain = pkgs.keychain.overrideAttrs {
    version = "2.9.5";
    src = pkgs.fetchurl {
      url = "https://github.com/funtoo/keychain/archive/refs/tags/2.9.5.tar.gz";
      hash = "sha256-yIPybbYWvByBul7zgyx62RLz6L0Lr2qv+YEWTFOKFBE=";
    };
  };
in {
  options.modules.gpg.enable = mkEnableOption "Configuration of GPG";

  config = mkIf cfg.enable {
    home.sessionVariables = {
      GPGKEY = gpgKey;
      GPG_TTY = "$(tty)";
    };

    home.packages = with pkgs; [
      seahorse        # Application for managing encryption keys and passwords in the GnomeKeyring
      keychain        # Keychain management tool for SSH and GPG keys -- deactivated since I need newer version
    ];

    programs.gpg = { enable = true; };

    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      enableZshIntegration = true;
      defaultCacheTtl = 604800; # 7 days
      defaultCacheTtlSsh = 604800; # 7 days
      maxCacheTtl = 604800; # 7 days
      maxCacheTtlSsh = 604800; # 7 days
      pinentry.package = pkgs.pinentry-rofi;
      extraConfig = ''
      '';
      sshKeys = gpgSshKeys;
    };

    home.file = {
      ".gnupg/gpg-key-public.asc".text = builtins.readFile ./../../secrets/gpg-key-public.asc;
    };

    home.activation = {
      import_gpg_keys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if ${pkgs.gnupg}/bin/gpg --list-keys --keyid-format short | grep -q "${gpgKey}"; then
          echo "GPG key ${gpgKey} already imported, skipping."
          exit 0
        fi

        ${pkgs.gnupg}/bin/gpg --import /home/${username}/.gnupg/gpg-key-private.asc
        ${pkgs.gnupg}/bin/gpg --import /home/${username}/.gnupg/gpg-key-public.asc
        rm /home/${username}/.gnupg/*.asc
      '';
    };
  };
}
