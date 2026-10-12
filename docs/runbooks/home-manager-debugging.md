# Runbook: Debugging home-manager and user secrets

Use this runbook when, after a login, reboot or rebuild, a user secret is missing (Atuin does not log in, SSH keys are gone, `zsh-secrets` is not loaded) or the `home-manager-jan.service` activation fails.

## Background

Secrets are decrypted in two tiers:

1. **NixOS (system)**: decrypts `agenix-home-key.age` to `/run/agenix/agenix-home-key`, using the SSH host key. The file belongs to the user.
2. **Home Manager (user)**: `agenix.service` (user unit, oneshot) uses that key to decrypt the user secrets to `/run/user/$(id -u)/agenix/`. SSH keys land as regular files in `~/.ssh/`.

User secrets: `atuin`, `zsh-secrets`, `gpg-key-private.asc`, `id_ed25519`, `id_ed25519-hetzner-sb`, `id_ed25519-jabasoft-ug`. The wiring is in `modules/nixos/secrets.nix` and `modules/home/secrets.nix`.

## Quick check

Run these in order and stop at the first step that does not match.

| # | Command | Expected |
| --- | --- | --- |
| 1 | `ls -la /run/agenix/agenix-home-key` | `-r-------- 1 jan users`. Listing the directory `/run/agenix/` fails for the user, the file itself is readable. |
| 2 | `systemctl status home-manager-jan.service` | `active (exited)` |
| 3 | `journalctl -u home-manager-jan.service -b \| tail -n 30` | Ends with `Finished Home Manager environment for jan`. |
| 4 | `systemctl --user status agenix.service` | `inactive (dead)` with `code=exited, status=0/SUCCESS`. The unit is a oneshot, so `dead` is the normal state. |
| 5 | `ls -la /run/user/$(id -u)/agenix/` | `atuin`, `gpg-key-private.asc`, `zsh-secrets`, all `-r--------` |
| 6 | `ls -la ~/.ssh/id_ed25519*` | The three keys with their `.pub` files, secrets `-r--------` |
| 7 | `atuin status` | A `[Remote]` block with `Username` |

## Symptoms and fixes

### Home key missing (step 1 fails)

The user tier cannot start without the system key.

1. Check the NixOS service: `systemctl status agenix.service` and `journalctl -u agenix.service -b` (system unit, needs no `--user`).
2. Check that the host key is listed for `agenix-home-key.age` in `secrets/secrets.nix`. A new host key needs `agenix --rekey`.

### User secrets not decrypted (step 4 or 5 fails)

1. Read the log: `journalctl --user -u agenix.service -b`. Each secret appears as `decrypting '<store path>' to '<target>'`.
2. Check that Home Manager points at the system key: `age.identityPaths` in `modules/home/secrets.nix` must be `/run/agenix/agenix-home-key`.
3. List the secrets the current configuration declares:

   ```bash
   nix eval .#nixosConfigurations.$(hostname).config.home-manager.users.jan.age.secrets \
     --apply 'secrets: builtins.attrNames secrets'
   ```

4. Restart the unit and check again: `systemctl --user restart agenix.service`.

### SSH keys not loading (step 6 fails)

1. Check permissions: `stat -c '%a %n' ~/.ssh/id_ed25519*`. Secrets must be `400` or `600`.
2. If the files are missing, follow "User secrets not decrypted".

### Atuin does not log in (step 7 fails)

Login is not an activation hook. The `atuinLogin` script (`modules/home/shell/atuin.nix`) runs from the zsh init.

1. Check the secret: `ls -la /run/user/$(id -u)/agenix/atuin`.
2. Run the login by hand: `atuinLogin`.
3. Check that the credentials are set, without printing the key:

   ```bash
   source /run/user/$(id -u)/agenix/atuin
   echo "User: $ATUIN_USER"
   echo "Key length: ${#ATUIN_KEY}"
   ```

4. Check that the zsh init calls it: `grep -r atuinLogin ~/.config/zsh/ ~/.zshrc 2>/dev/null`.

### User units not updated after a rebuild

1. Check that the reload ran: `journalctl -u home-manager-jan.service -b | grep daemon-reload`.
2. Reload by hand: `systemctl --user daemon-reload`.
3. Check the age of the unit file: `stat -c '%y %n' ~/.config/systemd/user/agenix.service`.

## Logs

```bash
journalctl -u home-manager-jan.service -f          # follow the activation
journalctl -u home-manager-jan.service -b          # current boot
journalctl -u home-manager-jan.service -p err -b   # errors only
journalctl --user -u agenix.service -b             # user-level secret decryption
journalctl -u home-manager-jan.service -b > /tmp/hm-activation.log   # export for analysis
```

## Re-running the activation by hand

```bash
HM=$(readlink -f ~/.local/state/nix/profiles/home-manager)
grep -A 10 agenix "$HM/activate"                                   # the agenix part of the script
VERBOSE=1 bash -x "$HM/activate" 2>&1 | tee /tmp/hm-activation-debug.log
```

## Verbose activation logs

`flake.nix` has `verbose = false` for Home Manager (`# Enable verbose home-manager activation`). Set it to `true`, rebuild, and read the result with `journalctl -u home-manager-jan.service`.

## After a rebuild

```bash
ls -la /nix/var/nix/profiles/system*-link | tail -n 3   # a new generation exists
systemctl status home-manager-jan.service
ls -la /run/user/$(id -u)/agenix/
```

## Secret flow

```
Boot / rebuild
  -> NixOS activation: agenix decrypts agenix-home-key.age
       -> /run/agenix/agenix-home-key (owner: jan)
  -> Home Manager activation: user agenix.service reads that key
       -> /run/user/$(id -u)/agenix/{atuin,zsh-secrets,gpg-key-private.asc}
       -> ~/.ssh/{id_ed25519,id_ed25519-hetzner-sb,id_ed25519-jabasoft-ug}
  -> Shell start: zsh init runs atuinLogin
       -> logs in to Atuin from /run/user/$(id -u)/agenix/atuin if not yet authenticated
```
