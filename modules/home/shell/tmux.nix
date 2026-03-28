{pkgs, ...}: {
  home.packages = with pkgs; [
    powerline
  ];

  programs.tmux = {
    enable = true;
    plugins = [
      pkgs.tmuxPlugins.resurrect
      {
        plugin = pkgs.tmuxPlugins.catppuccin;
        extraConfig = ''
          # Configure catppuccin before it initializes
          set -g @catppuccin_flavor "mocha"
          set -g @catppuccin_window_status_style "basic"
          set -g @catppuccin_window_text "#W"
          set -g @catppuccin_window_current_text "#W"
          set -g status-right-length 101
          set -g status-left-length 100
          set -g status-left ""
          set -g status-right "#{E:@catppuccin_status_application}#{E:@catppuccin_status_session}"
        '';
      }
    ];
    extraConfig = ''
      # unbind default prefix and set it to Ctrl+a
      unbind C-b
      set -g prefix C-a
      bind C-a send-prefix

      # Act like Vim
      set-window-option -g mode-keys vi
      bind-key h select-pane -L
      bind-key j select-pane -D
      bind-key k select-pane -U
      bind-key l select-pane -R

      # Look good
      set-option -g default-terminal "screen-256color"
      set-option -sa terminal-features "xterm-kitty:RGB"

      # Enable mouse support (works in iTerm)
      set-window-option -g mouse on

      # This is important to enable the mouse scrolling
      bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'select-pane -t=; copy-mode -e; send-keys -M'"
      bind -n WheelDownPane select-pane -t= \; send-keys -M

      # set up layouts
      # set main-pane-width 130

      # scrollback buffer size increase
      set -g history-limit 500000

      # C-a C-b will swap to last used window
      bind-key C-b last-window

      # Start tab numbering at 1
      set -g base-index 1

      # Allows for faster key repetition
      set -s escape-time 0

      # use different keys to split vertical and horizonal
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Change cursor in vim to distinguish between insert and command mode
      # Use in conjunciton with tmux-cursors.vim
      set-option -g terminal-overrides '*88col*:colors=88,*256col*:colors=256,xterm*:XT:Ms=\E]52;%p1%s;%p2%s\007:Cc=\E]12;%p1%s\007:Cr=\E]112\007:Cs=\E]50;CursorShape=%?%p1%{3}%<%t%{0}%e%p1%{2}%-%;%d\007'

      # reload config file
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config Reloaded!"

      # Use vim keybindings in copy mode
      setw -g mode-keys vi

      # set vi mode for copy mode
      setw -g mode-keys vi

      # more settings to make copy-mode more vim-like
      bind -T copy-mode-vi C-v send -X rectangle-toggle
      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi y send -X copy-selection_and_cancel
      bind -T copy-mode-vi Escape send -X cancel

      bind-key -T copy-mode-vi Enter send -X copy-pipe-and-cancel "wl-copy"
      bind-key -T copy-mode-vi y send -X copy-pipe-and-cancel "wl-copy"

      # Increase the time for displaying the pane numbers
      set -g display-panes-time 2000 #2s

      # Start the numbers for panes with 1
      set -g pane-base-index 1

      # set default path for new windows
      bind c new-window -c '#{pane_current_path}'

      # set default path for new windowsneovim
      bind c new-window -c '#{pane_current_path}'

      # Move current window to left or right
      bind-key -n C-S-Left swap-window -t -1
      bind-key -n C-S-Right swap-window -t +1

      # Bind special key to clear to tmux history
      bind-key C-S-L clear-history

      # Create a new window with predefined panes
      bind-key F2 split-window -v -p 25 -c '#{pane_current_path}' \; split-window -h -p 50 -c '#{pane_current_path}' -t 2 \; select-pane -t 1

      # Please don't rename the window names after I named it manually
      set-option -g allow-rename off

      # Required for support in nvim
      set-option -g focus-events on
    '';
  };

  home.shellAliases = {
    mux = "tmux new -d -s delete-me && tmux run-shell ${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/restore.sh && tmux kill-session -t delete-me && tmux attach || tmux attach";
  };

  home.sessionVariables = {
  };

}
