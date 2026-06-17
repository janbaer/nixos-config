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

## Helper Scripts

Wrapper scripts in the repo root for everyday rebuild, inspection, and maintenance tasks.

**Build & apply**

- `./nixos-switch.sh` — `nixos-rebuild switch --flake .` plus a reboot check.
- `./nixos-rebuild-verbose.sh` — verbose rebuild with trace and log capture in `/tmp`.

**Inspect generations**

- `./nixos-show-lastchanges.sh` — changes since the last rebuild.
- `./nixos-show-allchanges.sh` — all changes between generations.
- `./nixos-rebuild-show-nextchanges.sh` — preview the next rebuild without applying.
- `./nixos-list-generations.sh` — list all generations and their status.
- `./nixos-generation-diff.sh <g1> <g2>` — compare two generations.
- `./nixos-reboot-required.sh` — check whether a reboot is needed.

**Maintenance**

- `./nixos-collect-garbage.sh` — delete old generations.
- `./nixos-check-pkg-channels.sh [package]` — compare a package's version across the stable channel tip, the locked `flake.lock` pin, and unstable (defaults to `noctalia-shell`). Use it to tell when a package floated from unstable via an overlay has been backported to stable and the overlay can be dropped.

## Encryption

This config uses [agenix](https://github.com/ryantm/agenix) to manage secrets.

### Adding a New Machine

1. Enable SSH on the new machine so it has a host key.
2. Read its public key: `ssh-keyscan -t ed25519 -p22022 $(hostname)`
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

## Migrations

Per-release breaking changes and how they were fixed live in [`CHANGELOG.md`](./CHANGELOG.md) — useful when rolling the same release out to the remaining hosts.

> **Apply major migrations with `boot`, never `switch`.** Use `sudo nixos-rebuild boot --flake .#<host>` (or `nh os boot .`) + reboot — *not* the usual `nh os switch .`. `switch` activates the new generation live and restarts `display-manager` on the running session; if the new greeter is broken, that hard-hangs the machine you're on — black screen, frozen cursor, dead VT. `switch` also runs the new userspace against the *still-running old kernel* (26.05 jumped 6.12 → 6.18 and switched to dbus-broker, a "switch inhibitor"). `boot` defers everything to a clean reboot so kernel + D-Bus + display-manager come up together, and a broken generation is recoverable from the systemd-boot menu instead of wedging the live session. `nh os switch .` stays fine for incremental day-to-day rebuilds.

## AI-Skills

It is recommended to use the Nix skill for questions about this config, NixOS, nix-darwin, Home Manager, or general Nix usage.
You can install it for Claude with

```bash
npx skills add https://github.com/shakhzodkudratov/nixos-and-flakes-skill --skill nix
```

