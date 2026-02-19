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

## Hints

- To find the SHA256 hash of a NixOS configuration file, use `nix-prefetch-url`.
