{ config, lib, pkgs, ... }:
with lib;
let
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
    home.file = {
    #   ".gnupg/public-key.gpg".text = builtins.readFile ./../../secrets/public-gpg-key.gpg;
    ".gnupg/gpg-agent.conf".text = builtins.readFile ./files/gpg-agent.conf;
    };

    programs.gpg = { enable = true; };

    home.packages = with pkgs; [
      # gnupg     # Modern release of the GNU Privacy Guard, a GPL OpenPGP implementation
      seahorse    # Application for managing encryption keys and passwords in the GnomeKeyring
      keychain    # Keychain management tool for SSH and GPG keys -- deactivated since I need newer version
    ];


    # home.activation = {
    #   import_gpg_keys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    #     /etc/profiles/per-user/${username}/bin/gpg --batch --import ~/.gnupg/private-key.gpg
    #     /etc/profiles/per-user/${username}/bin/gpg --batch --import ~/.gnupg/public-key.gpg
    #     rm ~/.gnupg/*.gpg
    #   '';
    # };
  };
}
