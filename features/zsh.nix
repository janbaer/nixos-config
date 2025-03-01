{pkgs, ...}: {

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
      lsa = "eza --long --header --git --all";
      n = "nvim";
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
    };
    sessionVariables = {
      EDITOR = "nvim";
    };
  };

  home.packages = with pkgs; [
  ];
}

