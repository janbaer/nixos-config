{pkgs, lib, username, ...}: {
  imports = [
    ./atuin.nix
    ./ghostty.nix
    ./gopass.nix
    ./lf.nix
    ./moc.nix
    ./neovim.nix
    ./tmux.nix
    ./yazi.nix
    ./zsh.nix
  ];

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [
      "--cmd cd"
    ];
  };

  programs.bat = {
    enable = true;
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    extraOptions = ["-l" "--icons" "--git" "-a"];
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

    ncdu            # Disk usage analyzer with an ncurses interface

    # system call monitoring
    strace          # system call monitoring
    ltrace          # library call monitoring
    lsof            # list open files

    # AI helpers
    tgpt            # ChatGPT in terminal without needing API keys

    mplayer         # CLI music player
  ];
}
