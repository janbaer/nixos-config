{ username, pkgs, ... }:
{
  imports = [
    ./../../modules/home
  ];

  # Trial: use the cached nixpkgs noctalia-shell (v4.7.6) instead of building the
  # flake's quickshell fork from source. Same v4 line, settingsVersion 59 matches.
  # Scoped to the VM first; promote to the shared module if it proves stable.
  programs.noctalia-shell.package = pkgs.noctalia-shell;

  modules = {
    dev = {
      claude.enable = true;
      devops-tools.enable = false;
      golang.enable = true;
      nodejs.enable = true;
      python.enable = true;
      rust.enable = true;
      vscode.enable = true;
    };
    desktop = {
      browsers.enable = true;
      hyprland.enable = true;
      noctalia.enable = true;
      thunderbird.enable = true;
    };
    shell = {
      gopass.enable = true;
      moc.enable = false;
      television.enable = true;
      yazi.enable = true;
    };
    gpg.enable = true;
    onepassword.enable = false;
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
  home.stateVersion = "25.05";

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
