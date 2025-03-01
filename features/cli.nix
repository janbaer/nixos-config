{pkgs, ...}: {
  imports = [
    ./zsh.nix
    ./neovim.nix
  ];

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.bat = {enable = true;};

  programs.direnv = {
    enable = true;
    nix-direnv.enable =
      true;
  };

  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    extraOptions = ["-l" "--icons" "--git" "-a"];
  };

  # Terminal based filemanager
  programs.lf = {
    enable = true;
    settings = {
      preview = true;
      drawbox = true;
      hidden = true;
      icons = true;
      theme = "Dracula";
      previewer = "bat";
    };
  };

  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    installVimSyntax = true;
  };

  home.packages = with pkgs; [
    fastfetch
    # lf # Terminal based filemanager

    # archives
    zip
    xz
    unzip
    p7zip

    # utils
    ripgrep 	# recursively searches directories for a regex pattern
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
    zoxide
    
    btop  	# replacement of htop/nmon
    iotop 	# io monitoring
    iftop 	# network monitoring

    # system call monitoring
    strace 	# system call monitoring
    ltrace 	# library call monitoring
    lsof 	# list open files
  ];
}

