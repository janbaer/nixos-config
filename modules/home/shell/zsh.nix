{ pkgs, ... }: {

  programs.zsh = {
    enable = true;
    autosuggestion = {
      enable = true;
      highlight = "fg=#ff00ff,bold,underline";
    };
    enableCompletion = true; # https://mynixos.com/home-manager/option/programs.zsh.enableCompletion
    dotDir = ".config/zsh";
    initContent = ''
      setopt CORRECT

      # Source local zshrc with local only settings
      [[ -f $ZDOTDIR/.zshrc.local ]] && source $ZDOTDIR/.zshrc.local

      [[ -f $HOME/.p10k.zsh ]] && source $HOME/.p10k.zsh

      [ -f $HOME/.fzf-init.zsh ] && source $HOME/.fzf-init.zsh

      # Config keys for Atuin together with Fzf and run init for Zsh
      [ -f $HOME/.config/atuin/atuin-setup.sh ] && source $HOME/.config/atuin/atuin-setup.sh

      [ -f $HOME/.cargo/env ] && source $HOME/.cargo/env

      # Some kubernetes things
      [ -f $HOME/.kube/kube-config.yaml ] && export KUBECONFIG=$HOME/.kube/kube-config.yaml

      # Source local zshrc with local bu specific settings, if file exists
      [ -f $ZDOTDIR/.zshrc.bu ] && source $ZDOTDIR/.zshrc.bu

      export KEYCHAIN_KEYS="$KEYCHAIN_KEYS_LOCAL $KEYCHAIN_KEYS_BU"
      [ -f $HOME/tmp/keychain_init_done ] && source $HOME/bin/init-keychain.sh

      if type zoxide &>/dev/null; then
        eval "$(zoxide init zsh --cmd cd)"
      fi

      source $ZDOTDIR/.functions

      [ -f $ZDOTDIR/.zsh-secrets ] && source $ZDOTDIR/.zsh-secrets

      [ -f $PWD/.zshrc.local ] && source $PWD/.zshrc.local
    '';
    plugins = [
      {
        name = "zsh-powerlevel10k";
        src = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/";
        file = "powerlevel10k.zsh-theme";
      }
    ];
    shellAliases = {
      l = "lf";
      lsa = "eza --long --header --git --all";
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      reload = "source $ZDOTDIR/.zshrc";
      kc = "$HOME/bin/init-keychain.sh";
    };
    sessionVariables = {
      EDITOR = "nvim";
      KEYCHAIN_KEYS_LOCAL = "";
      DIRENV_LOG_FORMAT= "";
    };
  };

  home.file = {
    "tmp/.keep".text = "";
    ".config/zsh/.zlogout" = {
      text = ''
        [ -f $HOME/tmp/keychain_init_done ] && rm -f $HOME/tmp/keychain_init_done
      '';
    };
  };

  home.sessionPath = [
    "$HOME/bin"
  ];
}
