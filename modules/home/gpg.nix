{ config, lib, pkgs, username, ... }:
with lib;
let cfg = config.modules.gpg;
in {
  options.modules.gpg.enable = mkEnableOption "Configuration of GPG";

  config = mkIf cfg.enable {
    home.file = {
      ".gnupg/public-key.gpg".text = builtins.readFile ./../../secrets/public-gpg-key.gpg;
      ".gnupg/gpg-agent.conf".text = ''
        use-agent
        allow-loopback-pinentry
      '';
    };

    home.packages = with pkgs; [
      seahorse # Application for managing encryption keys and passwords in the GnomeKeyring
    ];

    programs.gpg = { enable = true; };

    home.activation = {
      import_gpg_keys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        /etc/profiles/per-user/${username}/bin/gpg --batch --import ~/.gnupg/private-key.gpg
        /etc/profiles/per-user/${username}/bin/gpg --batch --import ~/.gnupg/public-key.gpg
        rm ~/.gnupg/*.gpg
      '';
    };
  };
}
