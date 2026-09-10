# Repository Guidelines

Flake-based NixOS and Home Manager configuration for user `jan`, across three
hosts (`jabasoft-tx`, `jabasoft-pc2`, `jabasoft-nixos-vm-01`).

## Layout

- `flake.nix`, `flake.lock`: entry point and pinned inputs.
- `hosts/`: host-specific definitions (`configuration.nix`, `home.nix`, hardware, variables).
- `modules/nixos/`: reusable NixOS modules (networking, backups, virtualization, secrets, etc.).
- `modules/home/`: reusable Home Manager modules (shell, desktop, dev tooling).
- `dev-shells/`: standalone development shells.
- `secrets/`: agenix-managed encrypted secrets (`*.age`) and `secrets.nix` mappings.
- `*.sh` in repo root: operational helpers for rebuilds, diffs, and generation inspection.

For build commands, coding style, testing, commit format, and PR guidelines,
read `CLAUDE.md` in this repository.
