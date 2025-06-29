{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.modules.dev.vscode;
in
{
  options.modules.dev.vscode.enable = mkEnableOption "VSCode with plugins";

  config = mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      profiles = {
        default = {
          userSettings = {
            diffEditor = {
              ignoreTrimWhitespace= false;
            };
            editor = {
              bracketPairColorization.enabled = true;
              guides.bracketPairs = "active";
            };
            go.useLanguageServer = true;
            window.zoomLevel= 1;
            workbench = {
              colorTheme = "Dracula Theme";
              statusBar.visible = true;
              settings.editor = "ui";
            };
          };

          keybindings = [
          ];

          # https://mynixos.com/search?q=vscode-extensions
          extensions = with pkgs.vscode-extensions; [
            golang.go
            dracula-theme.theme-dracula
            enkia.tokyo-night
            redhat.vscode-yaml
            redhat.ansible
            bbenoist.nix
            jnoortheen.nix-ide
            vscodevim.vim
            hashicorp.hcl
          ];
        };
      };
    };
  };
}

