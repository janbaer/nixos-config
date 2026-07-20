{ username, ... }:
let
  vars = import ./variables.nix;
in
{
  imports = [
    ./../../modules/home
  ];

  home.shellAliases = vars.aliases;

  modules = {
    dev = {
      bun.enable = true;
      claude.enable = true;
      devops-tools.enable = true;
      golang.enable = true;
      goose-cli.enable = false;
      hunk.enable = true;
      k8s-cli.enable = true;
      mongodb.enable = true;
      nodejs.enable = true;
      python.enable = true;
      rust.enable = true;
      vscode.enable = true;
      zed-editor.enable = true;
    };
    desktop = {
      browsers.enable = true;
      dictate = {
        enable = true;
        model = "mistralai/voxtral-mini-transcribe";
      };
      hyprland.enable = true;
      noctalia.enable = true;
      noctalia.vpnToggle.enable = false; # desktop: no wg0 connection here
      noctalia.autoLock.enable = false; # trusted desktop: never lock, no password prompt
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
      television.enableK8sAliases = true;
      tomb.enable = true;
      yazi.enable = true;
    };
    gpg.enable = true;
    onepassword.enable = true;
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
  home.stateVersion = "25.05";

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
