# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a NixOS configuration repository that manages multiple systems using Nix Flakes, Home Manager, and agenix for secrets management. It's using the Nix flakes and I recently upgraded NixOS to the 25.05 release. Beside to the NixOS module, I'm using also the home-manager for managing the home-directory of the user. The configuration supports three systems: `jabasoft-vm-nixos-02`, `jabasoft-nb-01`, and `jabasoft-tx`, all running for user `jan`.

## Architecture

### Flake Structure
- `flake.nix`: Defines inputs (nixpkgs 25.05, home-manager, agenix, hyprland) and outputs with `mkSystem` helper function
- Each system configuration follows the pattern: `./hosts/${hostname}/configuration.nix` and `./hosts/${hostname}/home.nix` and also {hostname}/variables.nix for host-specific variables for usage in sub-modules.

### Module Organization
- `hosts/`: Per-system configurations with `configuration.nix`, `hardware-configuration.nix`, `home.nix`, and `variables.nix`
- `hosts/common/`: Shared configurations across all hosts
- `modules/nixos/`: System-level NixOS modules (openssh, yubikey, mailbox-drive, etc.)
- `modules/home/`: Home Manager modules organized by category:
  - `shell/`: Terminal tools (zsh, tmux, neovim, lf, atuin, etc.)
  - `dev/`: Development tools (git, golang, nodejs, rust, vscode, k8s-cli, claude)
  - `desktop/`: Desktop environment (hyprland, browsers, veracrypt)

### Secrets Management
- Uses agenix for encrypting secrets with SSH keys
- `secrets/secrets.nix` defines which secrets are encrypted for which SSH keys
- All systems share the same encrypted secrets using their respective SSH public keys

## Common Commands

### System Management
```bash
# Build and switch NixOS configuration
./nixos-switch.sh  # or: nixos-rebuild switch --use-remote-sudo --flake .

# Show changes from last rebuild
./nixos-show-lastchanges.sh  # or: nix store diff-closures /run/*-system

# Show all changes
./nixos-show-allchanges.sh

# Show next changes without switching
./nixos-rebuild-show-nextchanges.sh

# Get system info
./nix-info.sh
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


### Additional info

Agenix can only be used, because it was not working for me in the home-manager modules.
