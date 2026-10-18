> **Status:** Draft — 2026-10-18
> **Open:** Condensed from the archived OpenSpec design documents, not re-checked against the current modules. The Groq outcome comes from a commit message only.

# Design decisions

Decisions that are not obvious from the code. Project overview and constraints are in `project.md`. The gitleaks integration has its own page, `gitleaks-git-hooks.md`.

## SSH: publickey plus TOTP (`modules/nixos/ssh-totp.nix`)

A host that sets `modules.sshTotp.enable` requires the SSH key and a TOTP code, but not the Unix password. Enabled on `jabasoft-tx` and `jabasoft-pc2`.

- **Own module.** The toggle stays independent of `openssh.nix`, which is on for every host. For that, `KbdInteractiveAuthentication` is `lib.mkDefault false` in `openssh.nix` and plain `true` in `ssh-totp.nix`. Two plain definitions would conflict at evaluation.
- **PAM rule defined directly.** `security.pam.services.sshd.googleAuthenticator.enable` evaluates to `true` but adds nothing to the stack: nixpkgs inserts the rule only if `unixAuth` is set, and key-only SSH sets it to `false`. Every login then ends in `pam_deny` as `Permission denied (keyboard-interactive)`. The module therefore sets `security.pam.services.sshd.rules.auth.google_authenticator` itself, ordered relative to `rules.auth.deny.order`. `control` must be `sufficient`. With `required` a correct code would still fall through to the final `deny`.
- **U2F off for sshd.** `yubikey.nix` enables `pam.u2f` with `sufficient` for all PAM services. A Yubikey touch alone would pass SSH and skip the second factor. `security.pam.services.sshd.u2f.enable = false` closes that. Other services keep U2F.
- **One shared secret.** `secrets/google-authenticator.age` decrypts on all hosts to `~/.google_authenticator`, so one authenticator entry works everywhere. Mode is `0600`, not `0400`: `pam_google_authenticator` writes to the file at login. A rebuild overwrites that state, which only narrows replay protection.
- **Enrollment is manual.** `google-authenticator` is interactive. The package is in `systemPackages` for that. Backup codes belong outside the repo.
- **Rollout.** Enable on a new host only while its console is within reach. Rollback is `sudo nixos-rebuild switch --rollback`.

## Claude identity on Forgejo (`modules/home/dev/claude.nix`)

Claude acts as the Forgejo user `claude`, so Jan can approve the PRs Claude opens. Forgejo does not count the poster's own approval.

- **Identity by remote, not by environment.** `GIT_AUTHOR_*` would also rewrite Claude's commits in GitHub repos, which must stay Jan's. `claudeRun` instead passes two `includeIf "hasconfig:remote.*.url:..."` entries through `GIT_CONFIG_COUNT`/`KEY_n`/`VALUE_n`. Patterns: `git@forgejo:*/**` and `ssh://git@forgejo/**`. Outside `claudeRun` nothing changes.
- **Known gaps.** A Forgejo remote in another spelling (HTTPS, `forgejo.home.janbaer.de`) falls back to Jan's identity. A `GIT_CONFIG_COUNT` set by the caller is overwritten. A `! git commit` inside a Claude session counts as Claude.
- **Old token stays.** `home/forgejo/api-token` is still used by `bin/mirror-forgejo-mcp.sh` in ansible-homelab.
- **No separate SSH key.** Forgejo does not care who pushes.
- **Not covered.** `openRouterClaude` exports no Forgejo token.

## Gitleaks in the git hooks (`modules/home/dev/git.nix`)

Mechanism, behavior and limits: `gitleaks-git-hooks.md`. The reasons behind it:

- **Scan in the dispatcher, binary from the store.** The hook never depends on `PATH`.
- **Push range from stdin.** `<local sha> --not --remotes` avoids `@{u}..HEAD`, which fails on new branches, and ranges built from `$1`, which break when `$1` is a URL.
- **`--platform gitea` on `pre-push` only.** Forgejo serves the `gitea` link format. A staged scan has no commits and prints no warning.
- **No extra bypass.** `--no-verify` stays. No server-side check, no baseline for old history.
- **Merge commits.** A secret only in a merge resolution is caught by `pre-push`, and a clean merge that brings in an old remote secret is blocked too.

## Dictation: Groq trial reverted

Tried in #36: Groq models for speech-to-text and cleanup through OpenRouter. Reverted in `690b54c`, Voxtral/Mistral stays.

- OpenRouter cannot pin a provider on the transcription endpoint, so STT ran on DeepInfra as often as on Groq. Pinning works for cleanup (chat completions).
- Groq STT was no real gain over Voxtral. Cleanup gained little over Mistral, and `gpt-oss-20b` added a closing "Vielen Dank." that nobody said.
- Do not repeat the trial without a direct Groq API call for STT, which means a new credential and script changes.
