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
      goose-cli.enable = false;
      k8s-cli.enable = true;
      hunk.enable = true;
      mongodb.enable = false;
      nodejs.enable = true;
      python.enable = true;
      rust.enable = true;
      vscode.enable = true;
      zed-editor.enable = true;
    };
    desktop = {
      browsers.enable = true;
      dictate.enable = true;
      hermes-desktop.enable = true;
      hyprland.enable = true;
      hyprland.batteryRefreshRate.enable = true; # 2.8K@120 is the biggest drain on battery
      noctalia.enable = true;
      noctalia.idle.enable = true; # laptop: blank at 5 min, suspend at 20
      noctalia.idle.batteryOnly = true; # on AC the machine is sent to sleep by hand
      noctalia.wifi.enable = true; # laptop: wlp1s0 present, show the Wi-Fi widget
      obsidian.enable = true;
      thunderbird.enable = true;
    };
    shell = {
      aichat.enable = true;
      gopass.enable = true;
      herdr.enable = true;
      moc.enable = true;
      tgpt.enable = true;
      television.enable = true;
      tomb.enable = true;
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
