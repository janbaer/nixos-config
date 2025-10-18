# Jans NixOS config

This repo contains the configuration for NixOS, NixDarwin and the Nix HomeManager for all of my systems.

## Initial steps

Before applying this config to a new machine, you need to activate the support for flakes to the current `configuration.nix` with adding the following line

`nix.settings.experimental-features = [ "nix-command" "flakes" ];`

## Tooling

I use the Nix helper [nh](https://github.com/viperML/nh) for easier execution of the Nix commands and better visibility to show diffs after a build was running.
If you want to use `nh` before the nix-config was applied for the first time, you need to run `nix shell nixpkgs#nh`, to be able to use the helper.

## Encryption

After creating a new VM you need to read the public SSH-Keys of the machine, to be able to encrypt the secrets with using these public keys. So you need to activate the SSHD server for having a machine key.
You can read the public key with `ssh-keyscan -t ed25519 -p23 $(hostname)` The key needs to be added to the `./secrets/secrets.nix` file. After adding the new key, you need to re-encrypt all of you secrets with `agenix --rekey`. [See also](https://github.com/ryantm/agenix?tab=readme-ov-file#rekeying)
To encrypt a file you can use either **agenix** with calling `agenix -e secret.age` or also `age -R ~/.ssh/id_ed25519.pub ~/.ssh/id_ed25519 > ./secrets/id_ed25519.age`. But this will only use the specified public key.
You can also pipe the content of a file to the **agenix** command with `cat ~/.ssh/id_ed25519.pub | agenix -e secret.age`. The file `secret.age` needs to be added before to the `./secrets/secrets.nix` file.

Before installing agenix, you can run agenix in a nix-shell with the command `nix shell github:ryantm/agenix`

[NixOS Wiki Agenix](https://nixos.wiki/wiki/Agenix)
[See also](https://jonascarpay.com/posts/2021-07-27-agenix.html)

## Steps after applying the nix-config for the first time.

### GPG Key Import

After the initial system setup on a new machine, you need to manually import your GPG private key. This is a one-time operation per machine.To do it, just run `gpg-import-my-keys` in your terminal.

## Known issues

- In case that the command `nix flake update` fails with a strange error like `failed to insert entry: invalid object specified - package.nix` it helped, to delete the `~/.cache/nix/` directory.

## Hints

- In case you need to know the SHA256 of the NixOS configuration, you can use `nix-prefetch-url` command, which returns the SHA256 hash of the file.
