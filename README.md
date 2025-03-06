# Jans NixOS config

This repo contains the configuration for NixOS, NixDarwin and the Nix-HomeManager for all of my systems.

## Tooling

I use the Nix helper [nh](https://github.com/viperML/nh) for easier execution of the Nix commands and better visibility to show diffs after a build was running.

## Encryption

After creating a new VM you need to read the public SSH-Keys of the machine, to be able to encrypt the secrets with using these public keys.

You can read the public keys with `ssh-keyscan jabasoft-vm-nixos-02`

[See also](https://nixos.wiki/wiki/Agenix)

To encrypt a file you can use either **agenix** with calling `agenix -e secret.age` or also `age -R ~/.ssh/id_ed25519.pub ~/.ssh/id_ed25519 > ./secrets/id_ed25519.age`. But this will only use the specified public key. If you want to use more than one key, you need to reencrypt the file with all keys with calling `agenix --rekey` [See also](https://github.com/ryantm/agenix?tab=readme-ov-file#rekeying)

Before installing agenix, you can run agenix in a nix-shell with the command `nix shell github:ryantm/ageni`

[See also](https://jonascarpay.com/posts/2021-07-27-agenix.html)
