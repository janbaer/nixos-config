# CHANGELOG

This file describes all changes in the project.

## 2026-09-23
---

- Git hooks now fall back to the repo's own `.git/hooks/<hook>`, and `pre-commit`, `commit-msg` and `pre-push` are dispatched next to `post-commit`. Setting `core.hooksPath` is what stops git from reading `.git/hooks` at all, so every hook a tool had installed there was dead without a symptom — `pre-commit install` in ansible-homelab had been writing a file nothing ever ran, and four spec files collected trailing blank lines across several PRs before anyone noticed
  - `.githooks/<hook>` still wins where both exist, so the 2026-09-12 convention is unchanged
  - The fallback resolves the directory with `git rev-parse --git-common-dir`, never `--git-path hooks/<name>`: that one resolves through `hooksPath` and hands the dispatcher back to itself, which would exec in a loop on every commit

## 2026-09-12
---

- Git hooks now dispatch to a repo-local `.githooks/<hook>` when one exists and is executable, so adding a hook to a new repo needs no wiring in this repo's `git.nix`
  - First use: `.githooks/post-commit` here warns once 15 commits have landed since `CHANGELOG.md` was last touched, ignoring routine `nixos: Updating flake...` bumps — the gap that let this file fall three months behind in the first place

## 2026-09-11
---

- Dictation reliability — daily-use hardening
  - Added OpenRouter voice dictation with an optional LLM cleanup pass; set Voxtral as the transcription model on pc2, and made both dictation models overridable via env vars
  - Fixed long dictations losing characters: `wtype` maps many characters onto few virtual keycodes, so adjacent characters sharing a keycode dropped one — replaced with a clipboard paste (Ctrl+V), restoring the previous clipboard content afterward
  - Moved the script out of a Nix string into `dictate.sh` with `DICTATE_*` env vars for syntax highlighting, shellcheck, and no rebuild-per-change; added `DICTATE_DEBUG=1` logging (duration, raw/cleaned transcript, timing) to pin down which stage drops words
  - Squashed a 13-commit latency branch: fixed dropped last words (fixed-size audio blocks plus PulseAudio's ~2s pipeline delay swallowed at SIGINT — switched to 48kHz capture over ALSA), and cut the 4–17s wait by uploading Ogg Vorbis instead of raw WAV and rejecting cleanup output whose length falls outside 60–160% of the raw transcript (the symptom of the cleanup model answering the dictation instead of cleaning it)
  - Fixed two presses racing to start `rec` (flock), a stale pidfile getting recycled by an unrelated process, a locked gopass agent aborting silently, and a forgotten recording filling RAM at ~35 MB/hour (now self-limits at 10 minutes)
  - Added `~/.config/dictate/vocabulary.txt` for short-lived proper nouns the cleanup model mishears, read at runtime with no rebuild needed; long-lived names (Hetzner, Anthropic, Fable, Vorstellungsgespräch) went into the permanent prompt list instead
  - Cleanup prompt now strips meaningless filler words (Ja, Also, Äh, Öh) from sentence starts, unless they carry real meaning

## 2026-09-07
---

- Hermes remote desktop agent (#29)
  - Added a `hermes-desktop` alias for reaching the NousResearch Hermes agent without typing the flake URL
  - Moved the client out of `home.packages` into its own flake output, built out-of-band via `nix build .#hermes-desktop --out-link ~/hermes-desktop` and wrapped in a script so the command needs no retyping — keeps the build alive across garbage collection without carrying its 2.86 GB (mostly Electron) into every generation
  - Stubbed out the bundled `hermesAgent` (1.49 GB), since the client only ever talks to the agent on `agent.home.janbaer.de`

## 2026-08-18
---

- Wired the existing GPG authentication subkey ("JABASOFT systems") into `authorizedKeys` in `hosts/common`, so all hosts and the VM reach each other over SSH without a second key — sshd had been running everywhere but `authorizedKeys` stayed empty, serving nobody

## 2026-08-16
---

- jabasoft-tx battery life: four to five and a half hours (#30, closes #28)
  - Nothing on this host previously distinguished AC from battery behavior. Added TLP (ASPM, runtime PM, WiFi power save, amdgpu ABM), a TCC battery profile capped at 3GHz, EPP power mode with turbo off, and stopped the display blanking while on mains power via a UPower-driven idle inhibitor
  - Removed tuxedo-rs's `tccd`, since it drove the same hardware as TCC
  - Measured on an idle desktop on battery: 11.11W → 7.80W, projecting to 5.5 hours instead of 3.9; added a battery-percentage display in graphical mode

## 2026-08-15
---

- Added the herdr CLI, packaged from the upstream release binary, with its config seeded via a copy-once activation script so herdr could rewrite it at runtime
  - That copy-once script only wrote `config.toml` when missing, so later changes in the repo never reached the running machine. Switched to a normal `xdg.configFile` symlink so the repo stays the source of truth; the runtime edits that mattered (keybindings, onboarding flag) moved into the repo file to survive the switch

## 2026-08-10
---

- Fixed a trivy version bump (0.70.0 → 0.74.0) that rebuilt silently and kept running the old source while reporting the new version: `fetchFromGitHub`'s store path comes from the hash and name, not the tag, so an unchanged hash reused the old cached source
  - Fixed by putting the version into the source name (`trivy-${version}-source`), so a bump can never hit an existing store path — it now always fetches, and a stale hash fails loudly instead of passing silently
  - 0.74.0 does not exist upstream; settled on 0.73.0, which needed a newer `go` than the lock had

## 2026-08-03
---

- Fixed umlauts no longer typable in GTK4 terminals on Wayland: since GTK 4.20, GTK delegates Compose/dead-keys to an IME instead of handling them itself, so without IBus or Fcitx, Compose silently stopped working in Ghostty, Nautilus and gedit (browsers were unaffected, since they decode Compose themselves). Fixed with `GTK_IM_MODULE=simple`, forcing the built-in Compose table back, at the cost of Wayland text-input/IME support in GTK apps

## 2026-07-09
---

- Packaged the hunk diff viewer and wired it into git and lazygit, enabled on jabasoft-tx
  - Fixed branch detection to work against either `main` or `master`

## 2026-06-26
---

- Replaced volta with mise for Node.js and global npm packages (closes #23)

## 2026-06-20
---

- jabasoft-pc2: added zram swap (zstd, 50%) and systemd-oomd as a memory safety net, after a swapless OOM event killed the whole Hyprland session (Noctalia included) when a ~16 GiB experiment exhausted RAM — systemd-oomd now kills the single worst cgroup under pressure before the kernel's global OOM killer takes the compositor down

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
