# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NixOS configuration for three systems (`jabasoft-tx`, `jabasoft-pc2`, `jabasoft-nixos-vm-01`) using Nix Flakes, Home Manager (integrated into NixOS, not standalone), and agenix for secrets management. All systems are for user `jan`. Targets NixOS 25.11.

## Architecture

### Flake Structure

`flake.nix` defines a `mkSystem` helper that wires together NixOS + Home Manager + agenix for each host:

```
mkSystem nixpkgs system hostname username userfullname
  → ./hosts/${hostname}/configuration.nix  (NixOS)
  → ./hosts/${hostname}/home.nix           (Home Manager)
  → agenix.nixosModules + agenix.homeManagerModules
```

Each host has four files:
- `configuration.nix` — NixOS system config
- `hardware-configuration.nix` — auto-generated hardware settings
- `home.nix` — Home Manager config
- `variables.nix` — host-specific values (extends `hosts/common/variables.nix`)

### Module Organization

- `modules/nixos/` — system-level NixOS modules (openssh, yubikey, docker, printing, tomb, wireguard, etc.)
- `modules/home/shell/` — terminal tools (zsh, tmux, neovim, lf, yazi, atuin, gopass, tomb, ghostty)
- `modules/home/dev/` — development tools (git, golang, nodejs, rust, vscode, k8s-cli, claude, zed-editor)
- `modules/home/desktop/` — desktop environment (hyprland, browsers, thunderbird)
- `hosts/common/` — shared configs: `default.nix`, `secrets.nix`, `variables.nix`

All modules follow the same enable/disable pattern:

```nix
{ config, lib, pkgs, ... }:
with lib;
let cfg = config.modules.dev.toolname;
in {
  options.modules.dev.toolname.enable = mkEnableOption "Description of tool";
  config = mkIf cfg.enable {
    home.packages = with pkgs; [ tool ];
  };
}
```

Enable in host configs:
- Home Manager: `hosts/${hostname}/home.nix` → `modules.dev.toolname.enable = true;`
- NixOS: `hosts/${hostname}/configuration.nix` → `modules.modulename.enable = true;`

### Secrets Architecture (Two-Tier)

Agenix **only works at the NixOS level**, not in Home Manager modules. To support user-level secrets, a bridging key is used:

1. NixOS agenix decrypts `agenix-home-key.age` → `/run/agenix/agenix-home-key` (owned by user)
2. Home Manager agenix reads that key → decrypts user secrets to `/run/user/$(id -u)/agenix/`

Keys are defined in `secrets/secrets.nix`. Adding a new machine requires running `agenix --rekey` after adding its SSH public key.

## Common Commands

### Build and Apply

```bash
# Enter dev shell (provides nh, nvd, nixfmt-classic)
nix-shell

# Quick rebuild with visual diff (alias in shell.nix)
nhs                                   # nh os switch .

# Standard rebuild
./nixos-switch.sh                     # nixos-rebuild switch --flake .

# Build one host without switching (for validation)
nix build .#nixosConfigurations.jabasoft-tx.config.system.build.toplevel

# Evaluate flake outputs (catch structural errors)
nix flake check

# Verbose rebuild with log capture in /tmp
./nixos-rebuild-verbose.sh
```

### Inspect Generations

```bash
./nixos-show-lastchanges.sh           # Changes since last rebuild
./nixos-show-allchanges.sh            # All changes between generations
./nixos-rebuild-show-nextchanges.sh   # Preview without applying
./nixos-list-generations.sh           # All generations + status
./nixos-generation-diff.sh <g1> <g2> # Compare two generations
./nixos-reboot-required.sh            # Check if reboot is needed
```

### Maintenance

```bash
./nixos-collect-garbage.sh            # Delete old generations
sudo nixos-rebuild switch --rollback  # Revert to previous generation
nix flake update                      # Update all flake inputs

# Format Nix files
nixfmt-classic **/*.nix

# If flake update fails with "invalid object specified"
rm -rf ~/.cache/nix/
```

### Secrets

```bash
nix shell github:ryantm/agenix        # Get agenix without installing

agenix -e secrets/secret-name.age    # Edit encrypted file
agenix --rekey                        # Re-encrypt after adding SSH keys

# For home-manager secrets (require bridging key)
agenix -i /run/agenix/agenix-home-key -e zsh-secrets.age

# Get SSH public key from new machine
ssh-keyscan -t ed25519 -p22022 $(hostname)
```

### Debugging Home Manager

```bash
journalctl -u home-manager-jan.service -f   # Live activation log
systemctl --user status agenix.service       # User-level secret decryption
ls -la /run/user/$(id -u)/agenix/           # Verify user secrets exist
```

See `DEBUG-HOME-MANAGER.md` for the full debugging workflow.

## Commit Style

Match existing commits: `<scope>: <short present-tense summary>`

Examples: `nixos: Updating flakes`, `desktop: Adding wayscriber to Hyprland environment`

Scopes: `nixos`, `shell`, `desktop`, `dev`, `backup`, `hosts`

## Key Notes

- **Container runtime**: Podman with `dockerCompat = true`, not Docker
- **Display manager**: GDM with Wayland + UWSM integration
- **SSH port**: 22022 (default defined in `hosts/common/variables.nix`)
- **Garbage collection**: Auto-runs daily, deletes generations older than 7 days
- **Nix-LD**: Enabled for unpatched dynamic binaries (needed for tools like Codeium)
- **Host variables**: Extended from common; accessed with `import ./../../../hosts/${hostname}/variables.nix`
- **Hyprland waybar scripts**: Live in `modules/home/desktop/hyprland/waybar/scripts/`
