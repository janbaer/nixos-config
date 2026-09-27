# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Skills

Always invoke the `nixos-best-practices` skill before making any changes to this repository.

If the skill is missing, install it with:

```bash
npx skills add https://github.com/lihaoze123/my-skills --skill nixos-best-practices
```

## Project Overview

Hosts, tech stack, architecture, secrets tiers and constraints are described in `docs/project.md`. The n8n PR reviewer reads the same file, so keep it current instead of repeating it here.

@docs/project.md

## Module Pattern

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

## Dev Shells

`dev-shells/` holds standalone flakes (go, rust, devops, claude-desktop, zed-editor, antigravity, trivy). Enter one from any directory with `nix develop path:$HOME/Projects/nixos-config/dev-shells/<name>`, or reference it from another project's `.envrc` via `use flake path:...`.

Only `trivy` pins a source version. `fetchFromGitHub` keys its store path on the hash and derivation name, not the tag, so bumping the version without also changing the source name (`name = "trivy-${version}-source"`) lets Nix reuse the old cached source silently. See `dev-shells/README.md` for the full procedure and how to tell a hash mismatch from a wrong tag in the build log.

## Common Commands

### Build and Apply

```bash
# Enter dev shell (provides nh, nvd, nixfmt)
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
./nixos-check-pkg-channels.sh [pkg]   # Compare a package's version: stable channel tip vs. flake.lock pin vs. unstable
sudo nixos-rebuild switch --rollback  # Revert to previous generation
nix flake update                      # Update all flake inputs

# Format Nix files
nixfmt **/*.nix

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

Format: `{scope} {emoji}: {message}`, following the global commit rules — same emoji set, same present-participle wording, and the subject states *why* the change happened, not what the diff shows.

Examples: `nixos 🔧: Updating flakes`, `dictation 🐛: Fixing characters dropped in longer dictations`

Commits before `f75f89a` predate this and carry no emoji. Leave them alone.

Scopes: `nixos`, `shell`, `desktop`, `dev`, `backup`, `hosts`, `dictation`

## Coding Style & Naming Conventions

- Follow `.editorconfig`: UTF-8, LF, final newline, 2-space indentation.
- Format Nix code with `nixfmt` before committing.
- Keep module names descriptive and lowercase (for example `backup-to-nas.nix`, `wireguard.nix`).
- Prefer small, composable modules over large host-specific blocks.

## Testing Guidelines

- Treat evaluation and build as the primary tests for config changes.
- For a change to the current host, build it: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`.
- For a change to a shared module, run `nix flake check` to validate all hosts.
- When changing secrets wiring, rekey and validate mappings in `secrets/secrets.nix`.

## Pull Request Guidelines

- Match the commit style above.
- A PR description should include:
  - What changed and why.
  - Affected hosts/modules.
  - Validation performed (build/check commands and key output).
  - Screenshots only for visible UI changes (Hyprland/Waybar/Rofi).

## Key Notes

- **Display manager**: GDM with Wayland + UWSM integration
- **SSH port**: 22022 (default defined in `hosts/common/variables.nix`)
- **Garbage collection**: Auto-runs daily, deletes generations older than 7 days
- **Nix-LD**: Enabled for unpatched dynamic binaries (needed for tools like Codeium)
- **Host variables**: Extended from common; accessed with `import ./../../../hosts/${hostname}/variables.nix`
- **Hyprland waybar scripts**: Live in `modules/home/desktop/hyprland/waybar/scripts/`
