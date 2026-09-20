## Why

SSH access across all three hosts is currently single-factor: a valid private key is enough to log in. A second factor limits the damage if a key is ever stolen or copied, matching the publickey+TOTP pattern already used at Jan's company. Forgejo issue #38.

## What Changes

- Add a new `modules.sshTotp` NixOS module that turns on PAM `google_authenticator` for the `sshd` PAM service (`security.pam.services.sshd.googleAuthenticator.enable`) and requires both factors via `AuthenticationMethods = "publickey,keyboard-interactive"`.
- Store the TOTP secret (`~/.google_authenticator`, created once by Jan running `google-authenticator` interactively) as a single agenix secret, decrypted to the same path on every host that enables the module — one enrollment, one authenticator entry, usable everywhere.
- Enable the module only on `jabasoft-pc2` for now (local console access there makes it safe to test); `jabasoft-tx` and `jabasoft-nixos-vm-01` stay on key-only auth until Jan confirms pc2 works, then get the same flag flipped on in a follow-up change.
- **BREAKING** (scoped to pc2 only): SSH login to `jabasoft-pc2` will require a TOTP code in addition to the SSH key once this ships.

## Capabilities

### New Capabilities
- `ssh-totp-2fa`: PAM-based TOTP second factor for SSH login, backed by a single agenix-managed secret shared across hosts.

### Modified Capabilities
(none — `ssh-users` group, port, and key-only settings in `modules/nixos/openssh.nix` are unaffected; this change only adds `KbdInteractiveAuthentication`/`AuthenticationMethods` on top)

## Impact

- New file: `modules/nixos/ssh-totp.nix`
- New agenix secret: `secrets/google-authenticator.age`, registered in `secrets/secrets.nix` under the existing `keys` (all three host keys + jan)
- `modules/nixos/openssh.nix`: `KbdInteractiveAuthentication` must flip from `false` to `true` so PAM's conversational TOTP prompt can run (this applies host-wide via the shared module — see design.md for how it stays safe on hosts where `sshTotp` is off)
- `hosts/jabasoft-pc2/configuration.nix`: enable `modules.sshTotp`
- No changes to `jabasoft-tx` / `jabasoft-nixos-vm-01` configs in this change
- Manual, out-of-repo step required from Jan: run `google-authenticator` once, save the backup codes, then `agenix -e secrets/google-authenticator.age` with that output
