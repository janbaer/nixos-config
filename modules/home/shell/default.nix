{pkgs, username, ...}: {
  imports = [
    ./zsh.nix
    ./tmux.nix
    ./neovim.nix
    ./atuin.nix
    ./gopass.nix
    ./moc.nix
    ./lf.nix
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
    age         # Modern encryption tool with small explicit keys

    fastfetch   # Actively maintained, feature-rich and performance oriented, neofetch like system information tool

    # archives
    zip
    xz
    unzip
    p7zip

    # utils
    ripgrep     # recursively searches directories for a regex pattern
    eza         # A modern replacement for ‘ls’
    fzf         # A command-line fuzzy finder
    duf         # Disk Usage/Free Utility
    # television  # Blazingly fast general purpose fuzzy finder TUI.

    # networking tools
    dnsutils    # `dig` + `nslookup`
    dog
    ldns        # replacement of `dig`, it provide the command `drill`
    ipcalc      # it is a calculator for the IPv4/v6 addresses

    # misc
    libnotify   # Library that sends desktop notifications to a notification daemon
    killall
    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd
    pwgen 
    wget
    
    btop            # replacement of htop/nmon
    htop
    iotop           # io monitoring
    iftop           # network monitoring

    # system call monitoring
    strace          # system call monitoring
    ltrace          # library call monitoring
    lsof            # list open files

    # AI helpers
    tgpt            # ChatGPT in terminal without needing API keys

    mplayer         # CLI music player
  ];
}
