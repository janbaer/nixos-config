# nixos-config

Declarative configuration for Jan's private NixOS machines, all for the user `jan`:

- `jabasoft-tx`: Tuxedo laptop, the daily driver
- `jabasoft-pc2`: desktop PC
- `jabasoft-nixos-vm-01`: test VM

## Tech stack

- Nix flakes on the NixOS 26.05 release channel (`nixpkgs` and Home Manager `release-26.05`). There is no unstable input.
- Home Manager is a NixOS module, not a standalone installation.
- agenix for secrets.
- Desktop: Hyprland with Noctalia. The `noctalia` flake tag must stay in step with `pkgs.noctalia`.
- Container runtime: Podman with `dockerCompat`, not Docker.

## Architecture

- `flake.nix` builds each host with `mkSystem`, which combines NixOS, Home Manager and agenix. It passes `username`, `userfullname`, `hostname`, `inputs` and `system` as specialArgs.
- `hosts/<host>/` contains `configuration.nix` (NixOS), `home.nix` (Home Manager), `hardware-configuration.nix` (generated) and `variables.nix`. `variables.nix` extends `hosts/common/variables.nix`.
- `hosts/common/default.nix` contains the shared host configuration and the overlays.
- `modules/nixos/` contains the system modules, in the flat namespace `modules.<name>`.
- `modules/home/{shell,dev,desktop}/` contains the Home Manager modules, in the namespace `modules.<area>.<name>`.
- Each module is disabled by default. A host turns it on in its `configuration.nix` or `home.nix`.
- `dev-shells/` contains standalone flakes. They are not part of the host configurations.

## Secrets

agenix decrypts secrets only at the NixOS level. So there are two tiers:

1. NixOS decrypts `agenix-home-key` to `/run/agenix/`.
2. Home Manager uses that key to decrypt the user secrets to `/run/user/<uid>/agenix/`.

The wiring lives in `modules/nixos/secrets.nix` and `modules/home/secrets.nix`. `secrets/secrets.nix` maps each `.age` file to a key list. A new host key requires `agenix --rekey`.

## Constraints

- A change to a shared module must not break the evaluation of any host (`nix flake check`).
- Each host is built and switched only on that host.
- A major release migration uses `sudo nixos-rebuild boot --flake .#<host>` (or `nh os boot .`) and a reboot, never `nh os switch .`/`nhs`. `switch` restarts `display-manager` against the still-running old kernel, and a broken greeter or kernel boundary hard-hangs the live session. `boot` keeps a broken generation recoverable from the systemd-boot menu. Day-to-day rebuilds may use `switch`.
- `CHANGELOG.md` records the breaking changes of each release. Check it before a release goes to another host.
- There is no CI. `.githooks/post-commit` only warns when `CHANGELOG.md` falls behind.
