{pkgs, ...}: {
  imports = [
    ./zsh.nix
    ./tmux.nix
    ./neovim.nix
    ./atuin.nix
  ];

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.bat = {
    enable = true;
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
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
    extraConfig = ''
    '';
    keybindings = {
      D = "delete";
    };
  };

  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    installVimSyntax = true;
    settings = {
      theme = "tokyonight";
      font-family = "ComicShannsMono Nerd Font Mono";
      font-size = 16;
      background-opacity = 0.7;
      background-blur-radius = 10;
      quick-terminal-animation-duration = 0;
      # Linux specific settings
      gtk-titlebar = false;
      # MacOS specific settings
      macos-titlebar-style = "hidden";
      keybind = "global:cmd+grave_accent=toggle_quick_terminal";
    };
  };

  home.packages = with pkgs; [
    fastfetch

    # archives
    zip
    xz
    unzip
    p7zip

    # utils
    ripgrep 	# recursively searches directories for a regex pattern
    eza 	# A modern replacement for ‘ls’
    fzf 	# A command-line fuzzy finder
    # television  # Blazingly fast general purpose fuzzy finder TUI.

    # networking tools
    dnsutils   	# `dig` + `nslookup`
    ldns 	# replacement of `dig`, it provide the command `drill`
    ipcalc  	# it is a calculator for the IPv4/v6 addresses

    # misc
    killall
    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd
    gnupg
    pwgen 
    
    btop            # replacement of htop/nmon
    htop
    iotop           # io monitoring
    iftop           # network monitoring

    # system call monitoring
    strace          # system call monitoring
    ltrace          # library call monitoring
    lsof            # list open files

    keychain        # Keychain management tool for SSH keys
  ];
}
