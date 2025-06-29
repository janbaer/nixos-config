# Jans NixOS config

This repo contains the configuration for NixOS, NixDarwin and the Nix-HomeManager for all of my systems.

## Tooling

I use the Nix helper [nh](https://github.com/viperML/nh) for easier execution of the Nix commands and better visibility to show diffs after a build was running.

## Encryption

After creating a new VM you need to read the public SSH-Keys of the machine, to be able to encrypt the secrets with using these public keys.

You can read the public keys with `ssh-keyscan jabasoft-vm-nixos-02`

[See also](https://nixos.wiki/wiki/Agenix)

To encrypt a file you can use either **agenix** with calling `agenix -e secret.age` or also `age -R ~/.ssh/id_ed25519.pub ~/.ssh/id_ed25519 > ./secrets/id_ed25519.age`. But this will only use the specified public key. If you want to use more than one key, you need to reencrypt the file with all keys with calling `agenix --rekey` [See also](https://github.com/ryantm/agenix?tab=readme-ov-file#rekeying)

You can also pipe the content of a file to the **agenix** command with `cat ~/.ssh/id_ed25519.pub | agenix -e secret.age`.

Before installing agenix, you can run agenix in a nix-shell with the command `nix shell github:ryantm/agenix`

[See also](https://jonascarpay.com/posts/2021-07-27-agenix.html)

## Known issues

- In case that the command `nix flake update` fails with a strange error like `failed to insert entry: invalid object specified - package.nix` it helped, to delete the `~/.cache/nix/` directory.

## Hints

- In case you need to know the SHA256 of the NixOS configuration, you can use `nix-prefetch-url` command, which returns the SHA256 hash of the file.
