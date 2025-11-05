{ pkgs, ... }: {
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
      keybind = [
        "global:cmd+grave_accent=toggle_quick_terminal"
        # Special keybinding for Claude-code
        # to handle shift+enter for new-line
        "shift+enter=text:\x1b\r"
      ];
    };
  };
}
