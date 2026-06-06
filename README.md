# Jan's NixOS Config

This repo contains the NixOS, nix-darwin, and Home Manager configuration for all my systems. [![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/janbaer/nixos-config)

## Initial Setup

Before applying this config to a new machine, enable flake support in the system's `configuration.nix`:

```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

## Tooling

I use [nh](https://github.com/viperML/nh) as a Nix helper for cleaner command output and post-build diffs. To use it before applying the config for the first time, run:

```bash
nix shell nixpkgs#nh
```

## Encryption

This config uses [agenix](https://github.com/ryantm/agenix) to manage secrets.

### Adding a New Machine

1. Enable SSH on the new machine so it has a host key.
2. Read its public key: `ssh-keyscan -t ed25519 -p23 $(hostname)`
3. Add the key to `./secrets/secrets.nix`.
4. Re-encrypt all secrets: `agenix --rekey`

### Encrypting a Secret

Use agenix to encrypt a file (it must already be listed in `secrets.nix`):

```bash
agenix -e secret.age
```

To pipe content directly:

```bash
cat ~/.ssh/id_ed25519.pub | agenix -e secret.age
```

To run agenix without installing it:

```bash
nix shell github:ryantm/agenix
```

### Home Manager Secrets

Some secrets use a dedicated `agenix-home-key` for Home Manager compatibility. To edit these, pass the key explicitly:

```bash
agenix -i /run/agenix/agenix-home-key -e zsh-secrets.age
```

See `secrets.nix` to identify which secrets require this key.

**References:** [NixOS Wiki — Agenix](https://nixos.wiki/wiki/Agenix) · [Jonas Carpay's guide](https://jonascarpay.com/posts/2021-07-27-agenix.html)

## First-Run Steps

After applying the config to a new machine, complete these one-time tasks:

### Import GPG Keys

Run `gpgImportKeys` in your terminal.

### Log In to Atuin

Atuin syncs shell history across machines. Run `atuinLogin` once per machine.

## Known Issues

- If `nix flake update` fails with `failed to insert entry: invalid object specified - package.nix`, delete `~/.cache/nix/` and retry.

## Nautilus / GVFS

The NAS shares (SMB, NFS) are mounted via `x-systemd.automount`. To prevent Nautilus from freezing ("Application not responding") when a server is offline, all remote mounts use the `x-gvfs-hide` option — GVFS ignores them completely and will never poll or display them in the sidebar.

The mounts still work normally from the terminal (e.g. `ls /mnt/music` triggers the automount). To browse the NAS from within Nautilus, use the address bar: `smb://jabasoft-ug/`.

## Hints

- To find the SHA256 hash of a NixOS configuration file, use `nix-prefetch-url`.

## Migration History

Breaking changes hit during major upgrades and how they were fixed — useful when rolling the same release out to the remaining hosts.

> **Apply major migrations with `boot`, never `switch`.** Use `sudo nixos-rebuild boot --flake .#<host>` (or `nh os boot .`) + reboot — *not* the usual `nh os switch .`. `switch` activates the new generation live and restarts `display-manager` on the running session; if the new greeter is broken (as the GDM 50 regression below was), that hard-hangs the machine you're on — black screen, frozen cursor, dead VT. `switch` also runs the new userspace against the *still-running old kernel* (26.05 jumped 6.12 → 6.18 and switched to dbus-broker, a "switch inhibitor"). `boot` defers everything to a clean reboot so kernel + D-Bus + display-manager come up together, and a broken generation is recoverable from the systemd-boot menu instead of wedging the live session. `nh os switch .` stays fine for incremental day-to-day rebuilds.

### 25.11 → 26.05 (GNOME/GDM 50, Hyprland 0.55)

Channel inputs moved to `nixos-26.05` / `release-26.05`, then `nix flake update`.

> **Re-run `nix flake update` after the bump.** Locking the channel pins a *snapshot* of `nixos-26.05`, not a moving pointer. A new release's first weeks get rapid bugfixes — the GDM fix below landed in `release-26.05` days *after* the initial bump, so the lock had to be advanced again (`nix flake update nixpkgs`) to include it.

**Tooling**

- `nixfmt-classic` is deprecated → devShell now uses `nixfmt` (RFC-style 1.x).

**NixOS / GDM**

- `services.displayManager.gdm.wayland` was *removed* (GNOME 50 is Wayland-only). Any definition — `true` or `false` — aborts evaluation; delete the line.
- **GDM 50 black screen / login loop** (greeter renders nothing, just a cursor): nixpkgs bug [#523332](https://github.com/NixOS/nixpkgs/issues/523332) — the greeter couldn't find `gnome-session` on its PATH. Fixed upstream ([#527101](https://github.com/NixOS/nixpkgs/pull/527101), backported to `release-26.05`); pulled in via `nix flake update nixpkgs`.

**Home Manager default changes** (auto-apply only at `home.stateVersion ≥ "26.05"`; pinned to legacy unless noted):

- `wayland.windowManager.hyprland.configType = "hyprlang"` — keep; the config is hyprlang, not Lua.
- `programs.firefox.configPath = ".mozilla/firefox"` — keep; the new XDG default would orphan the existing profile.
- `programs.yazi.shellWrapperName = "yy"` — keep; the new `"y"` clashes with the `y = "yazi"` alias.
- `gtk.gtk4.theme = null` — adopted the new default.
- `programs.neovim.withRuby = false` — adopted the new default (no Ruby plugins).

**Neovim + dotfiles symlink collision**

- `programs.neovim` writes a provider `init.lua` that collides with the out-of-store `~/.config/nvim` symlink under 26.05's stricter file check (`Error installing file '.config/nvim/init.lua' outside $HOME`). Fix: `programs.neovim.sideloadInitLua = true` — provider config is loaded via wrapper args instead of being written to disk.

**Hyprland 0.55 config**

- `dwindle:pseudotile` removed — drop it; pseudotiling is now only the `pseudo` dispatcher.
- `togglesplit` is no longer a standalone dispatcher → `bind = …, layoutmsg, togglesplit`.
- Inline `windowrule = effect,matcher` removed → block form. In Home Manager use a list of attrsets (one `windowrule {}` block each); each needs a `name`, since `windowrule` is a "special category" keyed by name: `{ name = "x"; "match:class" = "^(foo)$"; float = true; }`.
- **hyprpaper** (hyprlang) does not expand `$HOME`; `preload = $HOME/...` silently fails. Bake an absolute path via `config.home.homeDirectory` interpolation.
- **hyprpaper 0.8 config format** (26.05 ships 0.8.4, rewritten on `hyprtoolkit`): the flat `preload = …` / `wallpaper = ,…` lines are *silently ignored* → `Monitor eDP-1 has no target: no wp will be created` and a missing wallpaper. Replace with the block form (empty `monitor =` targets all outputs):
  ```
  wallpaper {
      monitor =
      path = /home/jan/.wallpaper.jpg
  }
  ```
  Note: `hyprctl hyprpaper <cmd>` returns "invalid hyprpaper request" with this build (IPC bridge mismatch), but the config-file path works. Refs: [Arch BBS 311381](https://bbs.archlinux.org/viewtopic.php?id=311381), [hyprwm/Hyprland #13549](https://github.com/hyprwm/Hyprland/discussions/13549).

**UWSM session bounce** (password accepted, returns to greeter)

- Occurred while the Hyprland config still had the 0.55 breaking errors above. Under UWSM the compositor runs as a managed systemd user service, so a fast non-zero exit bounces straight back to the greeter (the plain "Hyprland" session was more lenient and ran with an error overlay). **Resolved once the config errors were fixed and the VM rebooted.** The `pinentry-rofi … Operation cancelled` lines seen during the bounce were a secondary symptom, not the cause. If it recurs, suspect a GUI pinentry invoked during UWSM's pre-compositor env preload — switch to a non-GUI pinentry (e.g. `pinentry-gnome3`).

**VM remote access (Proxmox + SPICE)**

- Remote SPICE needs Display = `SPICE (qxl)`, not `VirGL GPU` (VirGL can't stream GL over the network). Added `services.spice-vdagentd.enable = true` for clipboard, dynamic resolution, and seamless mouse.

## AI-Skills

It is recommended to use the Nix skill for questions about this config, NixOS, nix-darwin, Home Manager, or general Nix usage.
You can install it for Claude with

```bash
npx skills add https://github.com/shakhzodkudratov/nixos-and-flakes-skill --skill nix
```

