# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a NixOS configuration repository that manages multiple systems using Nix Flakes, Home Manager, and agenix for secrets management. The configuration uses NixOS 25.05 and supports three systems: `jabasoft-vm-nixos-02`, `jabasoft-nb-01`, and `jabasoft-tx`, all running for user `jan`.

## Architecture

### Flake Structure
- `flake.nix`: Defines inputs (nixpkgs 25.05, home-manager, agenix, hyprland) and outputs with `mkSystem` helper function
- Each system configuration follows the pattern: `./hosts/${hostname}/configuration.nix`, `./hosts/${hostname}/home.nix`, and `./hosts/${hostname}/variables.nix` for host-specific variables

### Module Organization
- `hosts/`: Per-system configurations with `configuration.nix`, `hardware-configuration.nix`, `home.nix`, and `variables.nix`
- `hosts/common/`: Shared configurations across all hosts (`default.nix`, `secrets.nix`)
- `modules/nixos/`: System-level NixOS modules (openssh, yubikey, mailbox-drive, docker, printing, etc.)
- `modules/home/`: Home Manager modules organized by category:
  - `shell/`: Terminal tools (zsh, tmux, neovim, lf, atuin, moc, gopass)
  - `dev/`: Development tools (git, golang, nodejs, rust, vscode, k8s-cli, claude, zed-editor)
  - `desktop/`: Desktop environment (hyprland, browsers, thunderbird, veracrypt)

### Host Variables Pattern
Each host defines variables in `variables.nix` including:
- `useHyprland`: Boolean for desktop environment
- `extraMonitorSettings`: Display configuration
- `gpgKey` and `gpgSshKeys`: GPG configuration
- `globalNpmPackages`: Host-specific npm packages
- Wireguard settings (`wgEndpoint`, `wgPublicKey`, etc.)

### Secrets Management
- Uses agenix for encrypting secrets with SSH keys
- `secrets/secrets.nix` defines which secrets are encrypted for which SSH keys
- All systems share the same encrypted secrets using their respective SSH public keys
- **Important**: Agenix only works at the NixOS level, not in home-manager modules

## Common Commands

### System Management
```bash
# Build and switch NixOS configuration
./nixos-switch.sh  # or: nixos-rebuild switch --use-remote-sudo --flake .

# Alternative with nh (nix-helper) - enter shell.nix first
nix-shell
nhs  # alias for: nh os switch .

# Show changes from last rebuild
./nixos-show-lastchanges.sh  # or: nix store diff-closures /run/*-system

# Show all changes
./nixos-show-allchanges.sh

# Show next changes without switching
./nixos-rebuild-show-nextchanges.sh

# Get system info
./nix-info.sh

# Format Nix files
nixfmt **/*.nix
```

### Secrets Management
```bash
# Enter agenix shell for encryption operations
nix shell github:ryantm/agenix

# Edit encrypted file
agenix -e secrets/secret-name.age

# Rekey all secrets after adding new SSH keys
agenix --rekey

# Get SSH public keys for new machines
ssh-keyscan hostname
```

### Home Manager Modules
When adding new development tools, follow the existing pattern in `modules/home/dev/`:
1. Create `toolname.nix` with enable option and package configuration
2. Add import to `modules/home/dev/default.nix`
3. Enable in host-specific `home.nix` with `dev.toolname.enable = true`

### Desktop Environment
The configuration uses Hyprland as the window manager with:
- waybar for status bar
- rofi for application launcher
- dunst for notifications
- hyprlock for screen locking
- Custom scripts in `modules/home/desktop/hyprland/waybar/scripts/`

When working with Hyprland configurations, note that dotfiles are managed through Home Manager and placed in appropriate XDG config directories.


## Development Shell

The repository includes a `shell.nix` that provides:
- `nh` (nix-helper) for better NixOS rebuilds with diffs
- `nixfmt` for formatting Nix code
- Alias `nhs` for quick system switching

```bash
# Enter development shell
nix-shell

# Use the alias for quick rebuilds
nhs
```

## Key SSH Public Keys

All systems use these SSH public keys for agenix encryption (defined in `secrets/secrets.nix`):
- `jan@janbaer.de`: Personal key
- `jabasoft-vm-nixos-01`, `jabasoft-nb-01`, `jabasoft-tx`: System keys

When adding a new system, update `secrets/secrets.nix` with the new SSH public key and run `agenix --rekey`.

## Important Notes

- **Agenix limitation**: Can only be used at NixOS level, not in home-manager modules
- **Host variables**: Each host in `hosts/*/variables.nix` defines `useHyprland`, monitor settings, GPG keys, npm packages, and Wireguard config
- **Module pattern**: Development tools follow enable/disable pattern with `dev.toolname.enable = true` in host `home.nix`
