## 1. Nix module

- [x] 1.1 Change `KbdInteractiveAuthentication` in `modules/nixos/openssh.nix` from plain `false` to `lib.mkDefault false`
- [x] 1.2 Create `modules/nixos/ssh-totp.nix`: `modules.sshTotp.enable` option; `services.openssh.settings = { KbdInteractiveAuthentication = true; AuthenticationMethods = "publickey,keyboard-interactive"; }`; `age.secrets.google-authenticator = { file = ../../secrets/google-authenticator.age; path = "/home/${username}/.google_authenticator"; owner = username; mode = "0600"; }`; `environment.systemPackages = [ pkgs.google-authenticator ]`
- [x] 1.2a Corrected after inspecting the built PAM file: `security.pam.services.sshd.googleAuthenticator.enable` never actually wires in (gated on `unixAuth`, which is `false` here) — replaced with a direct `security.pam.services.sshd.rules.auth.google_authenticator` rule (`control = "sufficient"`, ordered just before `deny`), plus `security.pam.services.sshd.u2f.enable = false` so a registered Yubikey can't bypass TOTP (see design.md 2a/2b)
- [x] 1.3 Add `./ssh-totp.nix` to `modules/nixos/default.nix` imports
- [x] 1.4 Register `"google-authenticator.age".publicKeys = keys;` in `secrets/secrets.nix`
- [x] 1.5 Set `modules.sshTotp.enable = true;` in `hosts/jabasoft-pc2/configuration.nix` only

## 2. Secret (manual, Jan only — not automatable)

- [x] 2.1 Jan: ran `google-authenticator` via `nix-shell -p google-authenticator`, saved backup codes
- [x] 2.2 Jan: `agenix -e secrets/google-authenticator.age`, pasted the resulting `~/.google_authenticator` contents
- [x] 2.3 Committed the new `secrets/google-authenticator.age` (folded into the existing commit via amend)

## 3. Build and verify

- [x] 3.1 `nix flake check` (passes)
- [x] 3.2 `nix build .#nixosConfigurations.jabasoft-pc2.config.system.build.toplevel` (succeeds)
- [x] 3.3 Jan: `nh os switch .` on pc2, ran the "How to Test" scenarios from issue #38 — confirmed working

## 4. Rollout to remaining hosts

- [x] 4.1a pc2 confirmed working by Jan; `modules.sshTotp.enable = true;` set on `jabasoft-tx` (Jan confirmed console access there for rollback)
- [x] 4.1b Jan: built and switched on jabasoft-tx itself, confirmed working
- [ ] 4.2 `jabasoft-nixos-vm-01` — out of scope for this change; issue #38 closed without it per Jan's call, would need a new issue if done later
