{ config, pkgs, username, ... }:

{
  # TODO please change the username & home directory to your own
  home.username = username;
  home.homeDirectory = "/home/${username}";

  # link the configuration file in current directory to the specified location in home directory
  # home.file.".config/i3/wallpaper.jpg".source = ./wallpaper.jpg;

  # link all files in `./scripts` to `~/.config/i3/scripts`
  # home.file.".config/i3/scripts" = {
  #   source = ./scripts;
  #   recursive = true;   # link recursively
  #   executable = true;  # make all files executable
  # };

  # encode the file content in nix configuration file directly
  # home.file.".xxx".text = ''
  #     xxx
  # '';

  # set cursor size and dpi for 4k monitor
  xresources.properties = {
    "Xcursor.size" = 18;
    "Xft.dpi" = 172;
  };

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    fastfetch
    lf # Terminal based filemanager

    # archives
    zip
    xz
    unzip
    p7zip

    # utils
    ripgrep 	# recursively searches directories for a regex pattern
    jq 		# A lightweight and flexible command-line JSON processor
    yq-go 	# yaml processor https://github.com/mikefarah/yq
    eza 	# A modern replacement for ‘ls’
    fzf 	# A command-line fuzzy finder
    television  # Blazingly fast general purpose fuzzy finder TUI.

    # networking tools
    dnsutils   	# `dig` + `nslookup`
    ldns 	# replacement of `dig`, it provide the command `drill`
    ipcalc  	# it is a calculator for the IPv4/v6 addresses

    # misc
    bat
    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd
    gnupg
    lazygit
    zoxide

    # nix related
    #
    # it provides the command `nom` works just like `nix`
    # with more details log output
    nix-output-monitor

    btop  	# replacement of htop/nmon
    iotop 	# io monitoring
    iftop 	# network monitoring

    # system call monitoring
    strace 	# system call monitoring
    ltrace 	# library call monitoring
    lsof 	# list open files

    # Development utils
    vscode

  ];

  # basic configuration of git, please change to your own
  programs.git = {
    enable = true;
    userName = "Jan Baer";
    userEmail = "jan@janbaer.de";
  };

  programs.zsh = {
    enable = true;
    autosuggestion = {
      enable = true;
      highlight= "fg=#ff00ff,bold,underline";
    };
    enableCompletion = true; # https://mynixos.com/home-manager/option/programs.zsh.enableCompletion
    dotDir = ".config/zsh";
    initExtra = ''
      if type zoxide &>/dev/null; then
        eval "$(zoxide init zsh --cmd cd)"
      fi
    '';
    shellAliases = {
      l = "lf";
      lg = "lazygit";
      lsa = " eza --long --header --git --all";
      n = "nvim";
      vim = "nvim";
    };
    sessionVariables = {
      EDITOR = "nvim";
    };
  };

  programs.vscode = {
    enable = true;

    userSettings = {

    };

    keybindings = [

    ];

    # https://mynixos.com/search?q=vscode-extensions
    extensions = with pkgs.vscode-extensions; [
      golang.go
      dracula-theme.theme-dracula
      enkia.tokyo-night
      redhat.vscode-yaml
      redhat.ansible
      bbenoist.nix
      jnoortheen.nix-ide
      vscodevim.vim
      hashicorp.hcl
    ];
  };

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
