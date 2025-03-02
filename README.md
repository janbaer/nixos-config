# Jans NixOS config

This repo contains the configuration for NixOS, NixDarwin and the Nix-HomeManager for all of my systems.

## Tooling

I use the Nix helper [nh](https://github.com/viperML/nh) for easier execution of the Nix commands and better visibility to show diffs after a build was running.

## Encryption

After creating a new VM you need to read the public SSH-Keys of the machine, to be able to encrypt the secrets with using these public keys.

You can read the public keys with `ssh-keyscan jabasoft-vm-nixos-02`

[See also](https://nixos.wiki/wiki/Agenix)
