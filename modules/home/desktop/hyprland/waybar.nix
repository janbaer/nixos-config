{ config, lib, pkgs, hostname, ... }: let
  inherit
    (import ./../../../../hosts/${hostname}/variables.nix)
    useHyprland
    ;

  # Noctalia replaces the bar; drop waybar where it is enabled.
  noctaliaEnabled = config.modules.desktop.noctalia.enable;

  # Workaround for Alexays/Waybar#5008: with Hyprland's Lua config the native
  # hyprland/workspaces click sends the legacy `dispatch workspace N`, which the
  # Lua dispatch parser rejects, so clicking a workspace icon does nothing.
  # Rewrite it to the Lua form `hl.dsp.focus({ workspace = "N" })`. Remove once
  # upstream fixes #5008. `--replace-fail` breaks the build loudly if a waybar
  # bump changes this line, signalling the patch needs revisiting.
  waybarLuaDispatch = pkgs.waybar.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/modules/hyprland/workspace.cpp \
        --replace-fail \
          '"dispatch workspace " + std::to_string(id())' \
          '"dispatch hl.dsp.focus({ workspace = \"" + std::to_string(id()) + "\" })"'
    '';
  });
in
{
  programs.waybar.enable = useHyprland && !noctaliaEnabled;
  programs.waybar.package = waybarLuaDispatch;
  home.file = {
    ".config/waybar".source = ./waybar;
  };
}
