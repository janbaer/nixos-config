# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a NixOS configuration repository that manages multiple systems using Nix Flakes, Home Manager, and agenix for secrets management. The configuration uses NixOS 25.11 and supports three systems: `jabasoft-tx`, `jabasoft-pc2`, and `jabasoft-nixos-vm-01`, all running for user `jan`.

## Architecture

### Flake Structure
- `flake.nix`: Defines inputs (nixpkgs 25.11, home-manager, agenix, hyprland) and outputs with `mkSystem` helper function
- Each system configuration follows the pattern: `./hosts/${hostname}/configuration.nix`, `./hosts/${hostname}/home.nix`, and `./hosts/${hostname}/variables.nix` for host-specific variables

### Module Organization
- `hosts/`: Per-system configurations with `configuration.nix`, `hardware-configuration.nix`, `home.nix`, and `variables.nix`
- `hosts/common/`: Shared configurations across all hosts (`default.nix`, `secrets.nix`)
- `modules/nixos/`: System-level NixOS modules (openssh, yubikey, mailbox-drive, docker, printing, etc.)
- `modules/home/`: Home Manager modules organized by category:
  - `shell/`: Terminal tools (zsh, tmux, neovim, lf, yazi, atuin, moc, gopass, tomb, ghostty)
  - `dev/`: Development tools (git, golang, nodejs, rust, vscode, k8s-cli, claude, zed-editor)
  - `desktop/`: Desktop environment (hyprland, browsers, thunderbird, veracrypt)

### Host Variables Pattern
Each host defines variables in `variables.nix` (extending `hosts/common/variables.nix`) including:
- `useHyprland`: Boolean for desktop environment
- `useTuxedo`: Boolean for Tuxedo hardware support (conditionally loads `tuxedo-flake.nix`)
- `extraMonitorSettings`: Display configuration for Hyprland
- `sshMatchBlocks`: Host-specific SSH configuration
- `gpgKey`: GPG key ID for signing
- `gpgSshKeys`: List of GPG SSH key fingerprints for various services
- `authorizedKeys`: SSH authorized keys for the host
- `wgEndpoint`, `wgAllowedIPs`, `wgPublicKey`, `wgIPAddress`: WireGuard VPN configuration
- `globalNpmPackages`: List of global npm packages to install with Volta
- `sshPort`: Custom SSH port (default: 22022)
- Additional host-specific settings as needed

### Secrets Management
- Uses agenix for encrypting secrets with SSH keys
- `secrets/secrets.nix` defines which secrets are encrypted for which SSH keys
- All systems share the same encrypted secrets using their respective SSH public keys
- **Important**: Agenix only works at the NixOS level, not in home-manager modules

## Common Commands

### System Management
```bash
# Build and switch NixOS configuration (also checks reboot required)
./nixos-switch.sh  # or: nixos-rebuild switch --use-remote-sudo --flake .

# Alternative with nh (nix-helper) - provides better diff output
nix-shell
nhs  # alias for: nh os switch .

# Show changes from last rebuild
./nixos-show-lastchanges.sh  # or: nix store diff-closures /run/*-system

# Show all changes between generations
./nixos-show-allchanges.sh

# Show next changes without switching (dry-run)
./nixos-rebuild-show-nextchanges.sh

# List all system generations and status
./nixos-list-generations.sh

# Compare two specific generations
./nixos-generation-diff.sh <gen1> <gen2>

# Get system info
./nix-info.sh

# Collect garbage (delete old generations)
./nixos-collect-garbage.sh

# Format Nix files (use nixfmt-classic from shell.nix)
nix-shell --run "nixfmt-classic **/*.nix"

# Check if reboot is required after updates
./nixos-reboot-required.sh

# Get SHA256 hash of files (useful for Nix)
nix-prefetch-url <url>

# Update flake inputs
nix flake update

# Rollback to previous generation
sudo nixos-rebuild switch --rollback
```

### Secrets Management
```bash
# Enter agenix shell for encryption operations
nix shell github:ryantm/agenix

# Edit encrypted file
agenix -e secrets/secret-name.age

# Encrypt file using specified keys
cat ~/.ssh/id_ed25519.pub | agenix -e secret.age

# Rekey all secrets after adding new SSH keys (must be done after adding to secrets.nix)
agenix --rekey

# Get SSH public keys for new machines (port 23 is custom SSH port)
ssh-keyscan -t ed25519 -p23 $(hostname)
```

### Module Development Pattern
Both NixOS modules (`modules/nixos/`) and Home Manager modules (`modules/home/`) follow a consistent enable/disable pattern:

**Home Manager Module Example (`modules/home/dev/toolname.nix`):**
```nix
{ config, lib, pkgs, ... }:
with lib;
let cfg = config.modules.dev.toolname;
in {
  options.modules.dev.toolname.enable = mkEnableOption "Description of tool";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ tool ];
    # Additional configuration...
  };
}
```

**NixOS Module Example (`modules/nixos/modulename.nix`):**
```nix
{ config, lib, ... }:
with lib;
let cfg = config.modules.modulename;
in {
  options.modules.modulename.enable = mkEnableOption "Description";

  config = mkIf cfg.enable {
    # NixOS system configuration...
  };
}
```

**Steps to add a new module:**
1. Create `toolname.nix` with the enable option pattern shown above
2. Add import to respective `default.nix` (`modules/home/dev/default.nix` or `modules/nixos/default.nix`)
3. Enable in host-specific config:
   - For home-manager: `hosts/${hostname}/home.nix` with `modules.dev.toolname.enable = true;`
   - For NixOS: `hosts/${hostname}/configuration.nix` with `modules.modulename.enable = true;`

### Desktop Environment
The configuration uses Hyprland as the window manager with:
- waybar for status bar
- rofi for application launcher
- dunst for notifications
- hyprlock for screen locking
- Custom scripts in `modules/home/desktop/hyprland/waybar/scripts/`
- GDM display manager with Wayland enabled
- UWSM (Universal Wayland Session Manager) integration

When working with Hyprland configurations, note that dotfiles are managed through Home Manager and placed in appropriate XDG config directories.

### Utility Scripts
The repository includes several shell scripts for common operations:
- `nixos-switch.sh` - Build, switch, and check reboot status
- `nixos-list-generations.sh` - List all generations with detailed status
- `nixos-generation-diff.sh` - Compare two specific generations
- `nixos-show-lastchanges.sh` - Show changes from last rebuild
- `nixos-show-allchanges.sh` - Show all changes between generations
- `nixos-rebuild-show-nextchanges.sh` - Preview changes without applying
- `nixos-collect-garbage.sh` - Clean up old generations
- `nixos-reboot-required.sh` - Check if reboot is needed
- `nix-info.sh` - Display system information
- `forgejo-create-pr.sh` - Create Forgejo pull requests


## Development Shell

The repository includes a `shell.nix` that provides:
- `nh` (nix-helper) for better NixOS rebuilds with visual diffs
- `nvd` (Nix/NixOS package version diff tool)
- `nixfmt-classic` for formatting Nix code
- Auto-generated `.zshrc.local` with alias `nhs` for quick system switching

```bash
# Enter development shell
nix-shell

# Use the alias for quick rebuilds with visual diffs
nhs  # equivalent to: nh os switch .

# Format Nix files
nixfmt-classic **/*.nix
```

## Secrets and SSH Configuration

### SSH Setup
- Custom SSH port: 22022 (defined in `hosts/common/variables.nix`)
- All systems use SSH keys for authentication
- Get machine keys: `ssh-keyscan -t ed25519 -p22022 $(hostname)`

### Agenix Encryption Keys
All systems use SSH public keys for agenix encryption (defined in `secrets/secrets.nix`):
- Personal key: `jan@janbaer.de`
- System keys: `jabasoft-tx`, `jabasoft-pc2`, `jabasoft-nixos-vm-01`

### Adding a New System
1. Ensure SSHD is running to generate machine keys
2. Read the public key: `ssh-keyscan -t ed25519 -p23 $(hostname)`
3. Add key to `./secrets/secrets.nix`
4. Re-encrypt all secrets: `agenix --rekey`
5. Secrets must be referenced in `hosts/common/secrets.nix`

**Important**: Agenix only works at the NixOS level (`configuration.nix`), not in Home Manager modules (`home.nix`).

## Troubleshooting

- **Nix flake update failures**: If `nix flake update` fails with errors like "failed to insert entry: invalid object specified - package.nix", delete the `~/.cache/nix/` directory
- **Missing dependencies**: Always check if libraries/packages are already available in the codebase before adding new ones
- **Agenix secrets**: Remember that agenix only works at the NixOS level (`configuration.nix`), not in Home Manager modules (`home.nix`)
- **Rollback**: If a rebuild breaks something, use `sudo nixos-rebuild switch --rollback` to revert to the previous generation
- **Generation comparison**: Use `./nixos-list-generations.sh` to see all available generations and their status
- **Home Manager debugging**: See `DEBUG-HOME-MANAGER.md` for detailed guidance on debugging home-manager activation and agenix secrets

## Important Notes

- **Module pattern**: Both NixOS and Home Manager modules follow consistent enable/disable pattern using `mkEnableOption` and `mkIf`
- **Host configuration**: Each host requires four files:
  - `configuration.nix` - NixOS system configuration
  - `hardware-configuration.nix` - Hardware-specific settings (auto-generated)
  - `home.nix` - Home Manager user configuration
  - `variables.nix` - Host-specific variables (extends `hosts/common/variables.nix`)
- **Shared configurations**: Common settings are stored in `hosts/common/` (default.nix, secrets.nix, variables.nix)
- **Variables pattern**: Host variables extend common variables; access with `import ./../../../hosts/${hostname}/variables.nix`
- **Automatic garbage collection**: Configured in `hosts/common/default.nix` to run daily, deleting generations older than 7 days
- **Flake structure**: The `mkSystem` helper function in `flake.nix` handles system creation with consistent specialArgs and module imports
- **Home Manager integration**: Integrated directly into NixOS configuration (not standalone), with `backupFileExtension = "hm-bak"`
- **Container runtime**: Uses Podman with Docker compatibility (`dockerCompat = true`) instead of Docker
- **Initial setup**: New machines need flakes enabled first: `nix.settings.experimental-features = [ "nix-command" "flakes" ];`
- **Nix-LD**: Enabled to run unpatched dynamic binaries on NixOS (useful for tools like Codeium)
- **Code generation**: When generating code, always follow @.editorconfig rules.

## Available Development Tools

The repository includes pre-configured modules for:

**Programming Languages:**
- Node.js (via Volta with automatic global package installation)
- Go (golang)
- Python
- Rust

**Development Tools:**
- git (with host-specific configuration)
- VSCode
- Zed Editor
- Claude Code
- Goose CLI
- MongoDB
- Kubernetes CLI tools (kubectl, k9s, etc.)
- DevOps tools (terraform, ansible, etc.)

**Container & Virtualization:**
- Podman (with Docker compatibility)
- lazydocker (accessible via `ld` alias)
- QEMU/KVM virtualization

**Shell & Terminal:**
- Zsh (with custom configuration)
- Tmux
- Neovim
- Ghostty terminal
- lf and yazi file managers
- atuin (shell history)
- gopass (password manager)

**Common Utilities:**
- direnv (with Nix integration)
- jq, gojq, jless (JSON processors)
- yq (YAML processor)
- httpie (HTTP client)
- meld (visual diff tool)
