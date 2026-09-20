## Context

`modules/nixos/openssh.nix` currently sets `KbdInteractiveAuthentication = false` and `PasswordAuthentication = false` for all three hosts, so SSH is key-only. NixOS ships PAM support for Google Authenticator TOTP out of the box via `security.pam.services.<name>.googleAuthenticator.enable` (module: `nixos/modules/security/pam.nix`, backed by `pkgs.google-authenticator` / `pam_google_authenticator.so`). Confirmed by reading the resolved nixpkgs source for this flake: the `sshd` PAM service NixOS's own `openssh` module registers already sets `unixAuth = false` whenever `PasswordAuthentication = false` — so turning on `googleAuthenticator.enable` does **not** also demand the Linux account password, matching the desired publickey+TOTP flow.

Secrets in this repo go through agenix (`secrets/secrets.nix`), either system-level (`keys` = jan + all three host keys, e.g. `yubico-u2f-keys.age` → `/home/${username}/.config/Yubico/u2f_keys`) or home-manager-level (`home-keys`). The Yubikey U2F key file is the closest existing precedent for "one personal secret file, present under the same path on multiple hosts."

## Goals / Non-Goals

**Goals:**
- Publickey + TOTP required for SSH login on `jabasoft-pc2`, no separate Unix-password prompt.
- One `google-authenticator` enrollment, reusable across all three hosts once rolled out further.
- No conflict with the existing `openssh.nix` module or its per-host settings.

**Non-Goals:**
- Enabling on `jabasoft-tx` / `jabasoft-nixos-vm-01` in this change (follow-up, after Jan verifies pc2).
- Automating the enrollment step itself — `google-authenticator` is interactive (shows a QR code, asks yes/no questions) and must be run by Jan, not by Nix or by Claude.
- Changing `AllowGroups`, the SSH port, or any other existing `openssh.nix` setting.

## Decisions

**1. New module `modules/nixos/ssh-totp.nix`, not folded into `openssh.nix`.**
Keeps the "which hosts require TOTP" toggle independent of the base SSH config, matching this repo's one-concern-per-module pattern (see `yubikey.nix`, `wireguard.nix`). Alternative considered: add the PAM/secret block directly inside `openssh.nix` — rejected, it would make the base SSH module's `enable` flag do double duty and couples an opt-in hardening feature to the always-on SSH module.

**2. `KbdInteractiveAuthentication` becomes `lib.mkDefault false` in `openssh.nix`; `ssh-totp.nix` sets it to plain `true`.**
`openssh.nix` is imported and `enable`d on every host, so its current plain `false` would collide with a plain `true` from `ssh-totp.nix` (Nix module system: two plain definitions of the same leaf option conflict at eval time). Wrapping the existing value in `mkDefault` keeps `false` as the value everywhere `ssh-totp` is off, while `ssh-totp.nix`'s plain `true` cleanly overrides it only on hosts where the module is enabled. `AuthenticationMethods` needs no such change since no other module sets it.

**2a. (Correction, found only by inspecting the built PAM file, not from reading the option docs) `security.pam.services.sshd.googleAuthenticator.enable` does NOT work here — the rule is defined directly instead.**
The initial plan was to use that convenience option. It evaluates to `true` correctly, but the actual `nixpkgs` PAM module only inserts the `google_authenticator` line into the stack when `(cfg.unixAuth || config.services.homed.enable)` is also true — a gate this repo's key-only setup never satisfies, since `unixAuth` is deliberately `false`. The option silently does nothing; every login then falls through to the PAM stack's unconditional final `pam_deny.so`, producing exactly `Permission denied (keyboard-interactive)` regardless of the TOTP code entered. Found by comparing `nix eval ...security.pam.services.sshd.googleAuthenticator.enable` (`true`) against the actual rendered `/etc/pam.d/sshd` on the built system (no `google_authenticator` line at all).
Fix: define the rule directly via the lower-level `security.pam.services.sshd.rules.auth.google_authenticator = { order; control; modulePath; settings; }`, which bypasses that gate. `order` is set as an offset from `rules.auth.deny.order` (NixOS's own documented pattern for this option, since built-in order values can shift between releases), landing the rule just before the final `deny`. `control = "sufficient"` is required, not `"required"`: a `"required"` module does not stop the stack on success, so a correct TOTP code would still fall through to the trailing `deny` (also `"required"`, unconditional) and get rejected anyway — `"sufficient"` is what makes a correct code actually end the stack with success, exactly mirroring how the pre-existing `unix`/`u2f` "main" entries are also `"sufficient"`.

**2b. (Also found during the same PAM trace) `yubikey.nix`'s global `security.pam.u2f.enable = true; control = "sufficient";` silently applies to every PAM service, sshd included.**
Before this change, a touch on Jan's already-registered Yubikey could authenticate SSH by itself (`"sufficient"`), bypassing any second factor entirely — unrelated to this change, but it directly undermines "publickey AND TOTP" if left alone. Jan chose to disable it for sshd specifically: `security.pam.services.sshd.u2f.enable = false;`. Every other PAM service (login, sudo, …) keeps U2F as before; this override is scoped to `sshd` only.

**3. TOTP secret stored as one agenix secret, decrypted the same way as the Yubikey pattern.**
`secrets/google-authenticator.age` → `age.secrets.google-authenticator = { file = ...; path = "/home/${username}/.google_authenticator"; owner = username; mode = "0600"; }`, registered under the existing `keys` list (jan + all three host keys) in `secrets/secrets.nix` — the same encrypted file decrypts identically on every host that has the key, giving Jan one authenticator entry for all three machines without re-enrolling per host. Alternative considered: a home-manager (`home-keys`) secret instead — rejected, would add an extra indirection through the bridging key for no benefit, and the Yubikey precedent already proves the system-level path works for personal per-user secret files.
Mode `0600` (not `0400`, unlike `agenix-home-key`) because `pam_google_authenticator` can rewrite this file at login time; a read-only file would break at the first login attempt.

**4. `pkgs.google-authenticator` added to `environment.systemPackages` in `ssh-totp.nix`.**
NixOS's PAM module only pulls in the `.so` for PAM itself; the interactive `google-authenticator` CLI Jan needs to run for enrollment isn't on `$PATH` unless the package is added explicitly.

## Risks / Trade-offs

- **[Risk] Rebuild wipes any runtime state `pam_google_authenticator` writes into `~/.google_authenticator`** (e.g. its anti-replay window) → agenix re-decrypts and overwrites the file on every `nixos-rebuild switch`/`nh os switch`. Mitigation: none needed — this only narrows the anti-replay protection across a rebuild event, it does not affect whether a valid code is accepted. Accepted trade-off, same as the existing Yubikey secret.
- **[Risk] Getting locked out of SSH on `jabasoft-pc2` if the PAM stack is misconfigured** → this is exactly why rollout is pc2-only in this change: Jan has local console access there, so a broken config is recoverable via `sudo nixos-rebuild switch --rollback` at the console, no remote dependency. `jabasoft-tx`/`jabasoft-nixos-vm-01` are deliberately excluded until pc2 is confirmed working.
- **[Risk] Backup/recovery codes** — `google-authenticator` prints one-time backup codes at enrollment; they're also embedded in the encrypted secret file but each is single-use. Mitigation: task below reminds Jan to save the printed codes outside the repo (e.g. password manager) during enrollment.

## Migration Plan

1. Jan runs `google-authenticator` locally (on pc2, after `pkgs.google-authenticator` is available), saves backup codes, gets `~/.google_authenticator`.
2. Jan encrypts it: `agenix -e secrets/google-authenticator.age` (paste the file contents), commits the resulting `.age` file.
3. Rebuild pc2 with `modules.sshTotp.enable = true`.
4. Verify a fresh SSH session (see issue's "How to Test") before rolling further.
5. Rollback path: `sudo nixos-rebuild switch --rollback` at the pc2 console if anything breaks; nothing to migrate back since no other host is touched.

## Open Questions

None blocking — flagged to Jan in the implementation-plan summary: confirm mode `0600` for `~/.google_authenticator` is acceptable (vs. a stricter `0400` that would break PAM's own state writes).
