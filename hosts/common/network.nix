{ pkgs, ... }:
{
  networking = {
    hosts = {
      "192.168.178.7" = [ "forgejo" ];
    };
  };
}
