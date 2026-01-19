{ config, lib, pkgs, username, ... }:
with lib;
let cfg = config.modules.shell.yazi;
in {
  options.modules.shell.yazi.enable = mkEnableOption "yazi terminal file manager";

  config = mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      settings = {
        mgr = {
          show_hidden = true;
          sort_by = "alphabetical";
          sort_dir_first = true;
        };
        preview = {
          image_delay = 100;
        };
      };
      keymap = {
        mgr.prepend_keymap = [
          { on = [ "S" ]; run = "shell \"$SHELL\" --block"; desc = "Open $SHELL here"; }
          { on = [ "<C-d>" ]; run = "shell --confirm 'sudo rm -rf \"$@\"' -- %s"; desc = "Delete selected files with sudo"; }
          { on = [ "t" ]; run = "plugin toggle-pane min-preview"; desc = "Toggle preview"; }
          { on = [ "T" ]; run = "plugin toggle-pane max-preview"; desc = "Maximize preview"; }
          { on = [ "g" "H" ]; run = "cd ~/"; desc = "Go to home directory"; }
          { on = [ "g" "D" ]; run = "cd ~/Documents"; desc = "Go to Documents"; }
          { on = [ "g" "d" ]; run = "cd ~/Downloads"; desc = "Go to Downloads"; }
          { on = [ "g" "P" ]; run = "cd ~/Projects"; desc = "Go to Projects"; }
          { on = [ "g" "p" ]; run = "cd ~/Pictures"; desc = "Go to Pictures"; }
          { on = [ "g" "V" ]; run = "cd ~/Videos"; desc = "Go to Videos"; }
          { on = [ "g" "M" ]; run = "cd ~/Music"; desc = "Go to Music"; }
          { on = [ "g" "m" ]; run = "cd /mnt/zb-data/metube/mp3"; desc = "Go to Metube music"; }
          { on = [ "g" "N" ]; run = "cd /home/${username}/mnt/mailbox-drive/Jan Baer/Notes/"; desc = "Go to Notes"; }
          { on = [ "g" "w" ]; run = "cd /run/media/${username}/MyNotes/Wochenberichte/2026/"; desc = "Go to Wochenberichte"; }
          { on = [ "g" "x" ]; run = "cd /run/media/${username}/xxx5/"; desc = "Go to xxx5"; }
          { on = [ "g" "c" ]; run = "cd ~/.config"; desc = "Go to .config"; }
          { on = [ "g" "b" ]; run = "cd ~/bin"; desc = "Go to bin"; }
        ];
      };
    };

    programs.zsh.shellAliases = {
      y = "yazi";
    };

    home.file = {
      ".config/yazi/plugins/toggle-pane.yazi/main.lua".source = ./files/yazi/plugins/toggle-preview.lua;
    };
  };
}
