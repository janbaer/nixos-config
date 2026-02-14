# Repository Guidelines

## Project Structure & Module Organization
This repository is a flake-based NixOS and Home Manager configuration.

- `flake.nix` and `flake.lock`: entry point and pinned inputs.
- `hosts/`: host-specific definitions (`configuration.nix`, `home.nix`, hardware, variables).
- `modules/nixos/`: reusable NixOS modules (networking, backups, virtualization, secrets, etc.).
- `modules/home/`: reusable Home Manager modules (shell, desktop, dev tooling).
- `dev-shells/`: standalone development shells.
- `secrets/`: agenix-managed encrypted secrets (`*.age`) and `secrets.nix` mappings.
- `*.sh` in repo root: operational helpers for rebuilds, diffs, and generation inspection.

## Build, Test, and Development Commands
- `nix-shell`: enter the project shell (includes `nh`, `nvd`, `nixfmt-classic`).
- `nix flake check`: evaluate flake outputs and catch structural issues early.
- `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`: build one host without switching.
  - Example: `nix build .#nixosConfigurations.jabasoft-tx.config.system.build.toplevel`
- `./nixos-switch.sh`: run `nixos-rebuild switch --flake .` and reboot check.
- `./nixos-rebuild-verbose.sh`: verbose rebuild with trace and log capture in `/tmp`.
- `./nixos-generation-diff.sh current previous`: inspect package-level generation changes.

## Coding Style & Naming Conventions
- Follow `.editorconfig`: UTF-8, LF, final newline, 2-space indentation.
- Format Nix code with `nixfmt-classic` before committing.
- Keep module names descriptive and lowercase (for example `backup-to-nas.nix`, `wireguard.nix`).
- Prefer small, composable modules over large host-specific blocks.

## Testing Guidelines
- Treat evaluation and build as the primary tests for config changes.
- For shared modules, build at least one affected host; for cross-host modules, build all impacted hosts.
- When changing secrets wiring, rekey and validate mappings in `secrets/secrets.nix`.

## Commit & Pull Request Guidelines
- Match existing commit style: `<scope>: <short present-tense summary>`.
  - Examples: `nixos: Updating flakes`, `desktop: Adding wayscriber to Hyprland environment`.
- Keep commits focused by concern (nixos, shell, desktop, dev, backup).
- PRs should include:
  - What changed and why.
  - Affected hosts/modules.
  - Validation performed (build/check commands and key output).
  - Screenshots only for visible UI changes (Hyprland/Waybar/Rofi).
