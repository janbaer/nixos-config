{ config, pkgs, lib, username, ... }: {
  # Terminal based filemanager
  programs.lf = {
    enable = true;
    settings = {
      preview = true;
      drawbox = true;
      hidden = true;
      icons = true;
      theme = "Dracula";
      previewer = "~/.config/lf/lf_kitty_preview";
      cleaner = "~/.config/lf/lf_kitty_cleaner";
      shell = "bash";
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
      gN = "cd /home/${username}/mnt/mailbox-drive/Jan Baer/Notes/";
      gw = "cd /home/${username}/Secure/MyNotes/Wochenberichte/2024/";
      gx = "cd /mnt/xxx5/";
      gc = "cd ~/.config";
      gb = "cd ~/bin";
    };
  };

  home.file = {
    ".config/lf/icons".source = ./files/lf/icons;
    ".config/lf/lfcd.sh".source = ./files/lf/lfcd.sh;
    ".config/lf/lf_kitty_clean.sh".source = ./files/lf/lf_kitty_clean;
    ".config/lf/lf_kitty_preview.sh".source = ./files/lf/lf_kitty_preview;
    ".config/lf/lf_commands".source = ./files/lf/lf_commands;
  };
}

