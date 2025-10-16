{ pkgs, hostname, ... }:
let
  inherit
    (import ./../../hosts/${hostname}/variables.nix)
  authorizedKeys;
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
        openssh.authorizedKeys.keys = authorizedKeys;
        shell = pkgs.zsh;
      };
    };
  };
}

