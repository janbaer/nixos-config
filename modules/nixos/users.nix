{ pkgs, hostname, username, userfullname, ... }:
let
  inherit
    (import ./../../hosts/${hostname}/variables.nix)
  authorizedKeys;
in {

  users = {
    groups = {
      ${username} = {
        gid = 1000;
      };
      ssh-users = {
        gid = 1001;
      };
    };
    users = {
      ${username} = {
        isNormalUser = true;
        description = userfullname;
        extraGroups = [ username "networkmanager" "wheel" "ssh-users" ];
        openssh.authorizedKeys.keys = authorizedKeys;
        shell = pkgs.zsh;
      };
    };
  };

}

