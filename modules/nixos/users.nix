{ pkgs, ... }: {

  users = {
    users = {
      jan = {
        isNormalUser = true;
        description = "Jan Baer";
        extraGroups = [ "networkmanager" "wheel" "ssh-users" ];
        # group = "jan";
        openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINZlTGJF57sVlu7Prmm41Y8GmaqpespwCMFB7fLROBSm jan@janbaer.de" ];
        packages = with pkgs; [];
        shell = pkgs.zsh; # Make Zsh as default shell
      };
    };
    # groups = {
    #   jan = {
    #     gid = 1000;
    #   };
    # };
  };
}

