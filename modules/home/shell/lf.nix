{ config, pkgs, lib, username, ... }: {

  home.packages = with pkgs; [
    chafa # Image preview for the Terminal
  ];

  # Terminal based filemanager
  programs.lf = {
    enable = true;
    settings = {
      drawbox = true;
      hidden = true;
      icons = true;
      preview = true;
      previewer = "~/.config/lf/lf_preview.sh";
      shell = "zsh";
      theme = "Dracula";
    };
    extraConfig = ''
      source "/home/${username}/.config/lf/lf_commands"
    '';
    keybindings = {
      d = null;
      m = null;
      w = null;
      "." = "set hidden!";
      D = "delete";
      "<c-d>" = "delete_with_sudo";
      dd = "trash";
      dr = "restore_trash";
      l = "lazy_git";
      p = "paste";
      x = "cut";
      y = "copy";
      "<enter>" = "open";
      r = "rename";
      R = "reload";
      mf = "mkfile";
      md = "mkdir";
      C = "clear";
      S = "$$SHELL";
      # -----------------------
      gH = "cd ~/";
      gD = "cd ~/Documents";
      gd = "cd ~/Downloads";
      gP = "cd ~/Projects";
      gp = "cd ~/Pictures";
      gV = "cd ~/Videos";
      gM = "cd ~/Music";
      gm = "cd /mnt/zb-data/metube/mp3";
      gN = "cd /home/${username}/mnt/mailbox-drive/Jan Baer/Notes/";
      gw = "cd /run/media/${username}/MyNotes/Wochenberichte/2026/";
      gx = "cd /run/media/${username}/xxx5/";
      gc = "cd ~/.config";
      gb = "cd ~/bin";
    };
  };

  home.file = {
    ".config/lf/icons".source = ./files/lf/icons;
    ".config/lf/lfcd.sh".source = ./files/lf/lfcd.sh;
    ".config/lf/lf_preview.sh".source = ./files/lf/lf_preview.sh;
    ".config/lf/lf_commands".source = ./files/lf/lf_commands;
  };
}
