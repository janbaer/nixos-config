# ssh-totp-2fa Specification

## Purpose
Require a TOTP code alongside the SSH key on hosts that opt in via `modules.sshTotp`, so a stolen or copied private key alone isn't enough for SSH access.
## Requirements
### Requirement: PAM TOTP second factor for SSH
When `modules.sshTotp.enable` is set on a host, SSH login to that host SHALL require a valid SSH key AND a valid TOTP code. It SHALL NOT additionally require the Unix account password.

#### Scenario: Login with valid key and correct TOTP code
- **WHEN** a client authenticates with an authorized SSH key and then supplies the current TOTP code for the enrolled `~/.google_authenticator`
- **THEN** the SSH session is established

#### Scenario: Login with valid key and missing or wrong TOTP code
- **WHEN** a client authenticates with an authorized SSH key and then supplies no code, an expired code, or an incorrect code
- **THEN** the SSH session is rejected

#### Scenario: Login with wrong SSH key
- **WHEN** a client presents a key that is not in the host's authorized keys
- **THEN** the SSH session is rejected before any TOTP prompt is offered

### Requirement: Shared TOTP secret across hosts
The TOTP secret SHALL be stored as a single agenix-encrypted file (`secrets/google-authenticator.age`) decryptable by `jan` and all three host keys, so the same authenticator entry validates logins on every host where `modules.sshTotp.enable` is set.

#### Scenario: Same code works on any enabled host
- **WHEN** `modules.sshTotp.enable` is set on two different hosts using the same `secrets/google-authenticator.age`
- **THEN** a TOTP code generated from Jan's single authenticator-app entry is accepted on both hosts

### Requirement: No alternate factor bypasses TOTP
On a host where `modules.sshTotp.enable` is set, no other configured PAM authentication factor (e.g. U2F/Yubikey) SHALL be able to satisfy SSH login on its own; TOTP SHALL be the only alternative to the SSH key.

#### Scenario: Registered Yubikey alone does not grant SSH access
- **WHEN** a client authenticates with an authorized SSH key and then presents a U2F/Yubikey response instead of a TOTP code
- **THEN** the SSH session is rejected

### Requirement: Hosts without the module keep key-only SSH
Hosts that do not set `modules.sshTotp.enable` SHALL be unaffected: SSH login there continues to require only a valid SSH key, with no TOTP prompt and no change to `KbdInteractiveAuthentication` behavior.

#### Scenario: Unmodified host still logs in with key only
- **WHEN** a client with an authorized SSH key connects to a host where `modules.sshTotp.enable` is false or unset
- **THEN** the SSH session is established without any TOTP prompt

