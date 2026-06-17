# CHANGELOG

This file describes all changes in the project.

## 2026-06-17
---

- Noctalia desktop shell integration (#15, #19, #20, #21)
  - Replaced waybar, dunst, wlogout and the rofi launcher with the Quickshell-based Noctalia shell — one `noctalia.nix` Home Manager module in place of ~5 separately-configured tools (~2,400 lines removed net)
  - Routed the Hyprland launcher/session/lock keybinds and the volume/brightness OSDs through Noctalia's IPC
  - Ported the WireGuard VPN status/toggle as a declarative Noctalia `CustomButton` (left-click toggle, polling status script, Nix-store paths only)
  - Added a Bluetooth widget, a keybindings cheat-sheet button, and app icons in the workspace pills
  - Made the VPN button and auto-lock opt-out per host (disabled on the VM and the trusted desktop)
  - Added a hypridle pre-sleep lock hook covering external suspends (lid close, power key, `systemctl suspend`)
  - Dropped `blueman` (Noctalia's Bluetooth panel handles scan/pair/connect/trust; OBEX unused) and hyprpaper (Noctalia owns the wallpaper)
  - Switched the icon theme to Papirus-Dark for tray-icon coverage; enabled sd-switch activation
  - Added `nixos-check-pkg-channels.sh` to tell when a package floated from unstable via an overlay has been backported to stable

## 2026-06-06
---

- NixOS 25.11 → 26.05 migration (GNOME/GDM 50, Hyprland 0.55)
  - Moved channel inputs to `nixos-26.05` / `release-26.05`, then re-ran `nix flake update` — twice, because the GDM fix below landed in `release-26.05` days after the initial bump and the lock had to be advanced again (`nix flake update nixpkgs`)
  - Tooling: `nixfmt-classic` is deprecated → devShell now uses `nixfmt` (RFC-style 1.x)
  - GDM: `services.displayManager.gdm.wayland` was removed (GNOME 50 is Wayland-only; any value aborts evaluation — delete the line)
  - Fixed the GDM 50 black-screen / login-loop (greeter renders only a cursor): nixpkgs [#523332](https://github.com/NixOS/nixpkgs/issues/523332) — greeter couldn't find `gnome-session` on PATH; fixed upstream ([#527101](https://github.com/NixOS/nixpkgs/pull/527101), backported to `release-26.05`) and pulled in via `nix flake update nixpkgs`
  - Home Manager default changes (auto-apply at `home.stateVersion ≥ "26.05"`; kept legacy unless noted):
    - `hyprland.configType = "hyprlang"` — kept at the bump, later rewritten to Lua (`configType = "lua"`) for the Noctalia integration
    - `programs.firefox.configPath = ".mozilla/firefox"` — kept; the new XDG default would orphan the existing profile
    - `programs.yazi.shellWrapperName = "yy"` — kept; the new `"y"` clashes with the `y = "yazi"` alias
    - `gtk.gtk4.theme = null` and `programs.neovim.withRuby = false` — adopted the new defaults
  - Fixed the neovim provider `init.lua` symlink collision with the out-of-store `~/.config/nvim` (26.05's stricter `outside $HOME` check) via `programs.neovim.sideloadInitLua = true`
  - Hyprland 0.55: dropped `dwindle:pseudotile`, moved `togglesplit` to a `layoutmsg`, converted `windowrule` to block form; fixed hyprpaper 0.8.4's silently-ignored flat config with the block form (`wallpaper { monitor = …; path = … }`) — later superseded, Noctalia now owns the wallpaper
  - Resolved a UWSM session bounce (password accepted, returns to greeter) once the 0.55 config errors above were fixed and the VM rebooted
  - VM remote access (Proxmox): SPICE needs Display = `SPICE (qxl)`, not `VirGL GPU`; added `services.spice-vdagentd.enable = true` for clipboard, dynamic resolution, and seamless mouse
  - **Lesson:** apply major migrations with `nixos-rebuild boot` + reboot, never `switch` — see the Migrations note in `README.md`
