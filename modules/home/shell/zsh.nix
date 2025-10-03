{ pkgs, lib, ... }:
with lib;
let
  zshCompletionsInit = pkgs.writeScriptBin "zshCompletionsInit" ''
    #!${pkgs.zsh}/bin/zsh
    rm -f $ZDOTDIR/.zcompdump
    mkdir -p $ZDOTDIR/completions
    rm $ZDOTDIR/completions/*

    echo "Fetching ZSH completions from GitHub..."
    ${pkgs.curl}/bin/curl -s -o $ZDOTDIR/completions/_httpie https://raw.githubusercontent.com/zsh-users/zsh-completions/master/src/_httpie
    ${pkgs.curl}/bin/curl -s -o $ZDOTDIR/completions/_age https://raw.githubusercontent.com/zsh-users/zsh-completions/master/src/_age
    ${pkgs.curl}/bin/curl -s -o $ZDOTDIR/completions/_golang https://raw.githubusercontent.com/zsh-users/zsh-completions/master/src/_golang
    ${pkgs.curl}/bin/curl -s -o $ZDOTDIR/completions/_terraform https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/refs/heads/master/plugins/terraform/_terraform

    

    echo "Generating more ZSH completions..."
    ${pkgs.volta}/bin/volta completions zsh > $ZDOTDIR/completions/_volta
    ${pkgs.podman}/bin/podman completion zsh > $ZDOTDIR/completions/_podman
    ${pkgs.uv}/bin/uv generate-shell-completion zsh > "$ZDOTDIR/completions/_uv"
    ${pkgs.uv}/bin/uvx --generate-shell-completion zsh > "$ZDOTDIR/completions/_uvx"

    # cp ./files/_terraform $ZDOTDIR/completions/_terraform

    fpath=($ZDOTDIR/completions $fpath)
    autoload -Uz compinit
    compinit
  '';
  
in 
{
  programs.zsh = {
    enable = true;
    autosuggestion = {
      enable = true;
      highlight = "fg=#ff00ff,bold,underline";
    };
    enableCompletion = true;
    completionInit = ''
      fpath=($ZDOTDIR/completions $fpath)
      autoload -Uz compinit
      if [[ ! -f $ZDOTDIR/.zcompdump ]]; then
        compinit
      else
        compinit -C
      fi
    '';
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
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];
    shellAliases = {
      l = "lf";
      lsa = "eza --long --header --git --all";
      lst = "eza --tree";
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      reload = "source $ZDOTDIR/.zshrc";
      kc = "$HOME/bin/init-keychain.sh";
      copy = "wl-copy";
      paste = "wl-paste --type=text/plain";
      timezsh="for i in $(seq 1 5); do time zsh -i -c exit; done";
      nushell="nix shell nixpkgs#nushell nixpkgs#carapace --command nu";
    };
    sessionVariables = {
      EDITOR = "nvim";
      DIRENV_LOG_FORMAT= "";
    };
  };

  home.file = {
    "tmp/.keep".text = "";
    ".config/zsh/.zlogout" = {
      text = ''
      '';
    };
  };

  home.packages = [
    zshCompletionsInit
  ];

  home.sessionPath = [
    "$HOME/bin"
  ];
}
