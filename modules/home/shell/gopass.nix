{ config, lib, pkgs, username, ... }:
with lib;
let
  cfg = config.modules.shell.gopass;
  passwordStoreDir = "/home/${username}/.password-store";
in {
  options.modules.shell.gopass.enable = mkEnableOption "Configuration of gopass";

  config = mkIf cfg.enable {
    home.file = {
      ".config/gopass/config".text = ''
        [mounts]
          path = ${passwordStoreDir}

        [recipients]
          hash = f00ea2203f44514737f5a50b55dd98af8983bf2cd192c78d466f3479a0d4ada2
      '';
    };

    home.packages = with pkgs; [
      gopass
    ];

    # home.activation = {
    #   cloning_password_store = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    #     if [ ! -d "${passwordStoreDir}" ]; then
    #       ${pkgs.git}/bin/git clone git@forgejo:jan/password-store.git ${passwordStoreDir}
    #     fi
    #   '';
    # };
  };
}

