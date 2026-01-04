{ username, ... }:
{
  imports = [
    ./../../modules/home
  ];

  modules = {
    dev = {
      bun.enable = true;
      claude.enable = true;
      devops-tools.enable = false;
      golang.enable = true;
      goose-cli.enable = true;
      k8s-cli.enable = true;
      mongodb.enable = false;
      nodejs.enable = true;
      python.enable = true;
      rust.enable = true;
      vscode.enable = true;
      zed-editor.enable = true;
    };
    desktop = {
      browsers.enable = true;
      hyprland.enable = true;
      thunderbird.enable = true;
      veracrypt.enable = true;
    };
    shell = {
      gopass.enable = true;
      moc.enable = true;
      yazi.enable = true;
    };
    gpg.enable = true;
    usb-automount.enable = true;
  };

  home.username = username;
  home.homeDirectory = "/home/${username}";

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "24.11";

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
