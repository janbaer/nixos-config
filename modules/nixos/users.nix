{ pkgs, ... }:
let
  pubSSHKey = builtins.readFile ../../secrets/id_ed25519.pub;
in {

  users = {
    groups = {
      jan = {
        gid = 1000;
      };
      ssh-users = {
        gid = 1001;
      };
    };
    users = {
      jan = {
        isNormalUser = true;
        description = "Jan Baer";
        extraGroups = [ "jan" "networkmanager" "wheel" "ssh-users" ];
        openssh.authorizedKeys.keys = [ pubSSHKey ];
        shell = pkgs.zsh;
      };
    };
  };
}

