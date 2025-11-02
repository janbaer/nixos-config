# Home-Manager Debugging Guide

This guide shows you how to monitor and debug home-manager with agenix secrets management.

## Architecture Overview

This configuration uses a two-tier encryption model:

1. **System-level (NixOS)**: Decrypts `agenix-home-key.age` to `/run/agenix/agenix-home-key`
   - Uses SSH host keys for decryption
   - Owned by the user, accessible at boot

2. **User-level (home-manager)**: Uses the decrypted key to decrypt user secrets
   - Secrets stored in `/run/user/$(id -u)/agenix/`
   - Includes: atuin, zsh-secrets, SSH keys, GPG keys

## 1. Configuration Changes

The flake.nix can be configured with `verbose = true` for home-manager to enable detailed logging during activation (currently commented out).

## 2. Monitoring Logs During Boot/Login

### Real-time Monitoring

After you reboot or log in, you can monitor home-manager activation in real-time:

```bash
# Watch home-manager activation logs as they happen
journalctl -u home-manager-jan.service -f

# Or with more context (shows timestamps and full output)
journalctl -u home-manager-jan.service -f -o verbose
```

### View Recent Activation Logs

```bash
# Show logs from current boot
journalctl -u home-manager-jan.service -b

# Show last 100 lines
journalctl -u home-manager-jan.service -n 100

# Show logs since last reboot
journalctl -u home-manager-jan.service --since "1 hour ago"

# Show logs with full context (no truncation)
journalctl -u home-manager-jan.service -b --no-pager
```

### Check User Agenix Service

```bash
# Check agenix service status
systemctl --user status agenix.service

# View agenix activation logs
journalctl --user -u agenix.service -b

# Real-time monitoring
journalctl --user -u agenix.service -f
```

## 3. Manual Testing After Login

### Test Home-Manager Activation Manually

```bash
# Activate current generation with verbose output
export VERBOSE=1
/nix/var/nix/profiles/system/activate-user

# Or activate specific generation
export VERBOSE=1
/nix/store/$(readlink /home/jan/.local/state/nix/profiles/home-manager)/activate
```

### Check Which Secrets Are Being Decrypted

```bash
# List all secrets in current home-manager config
nix eval .#nixosConfigurations.jabasoft-tx.config.home-manager.users.jan.age.secrets \
  --apply 'secrets: builtins.attrNames secrets'

# Verify the system-level home key was decrypted
ls -la /run/agenix/agenix-home-key

# Check user-level secrets directory
ls -la /run/user/$(id -u)/agenix/

# Expected user secrets:
# - atuin (atuin shell history credentials)
# - zsh-secrets (ZSH environment secrets)
# - gpg-key-private.asc (GPG private key)
# Plus SSH keys in ~/.ssh/ (symlinked from secrets)
```

## 4. Debugging Activation Script

### View Current Activation Script

```bash
# View the complete activation script
cat $(readlink /home/jan/.local/state/nix/profiles/home-manager)/activate

# Search for agenix-related activation
cat $(readlink /home/jan/.local/state/nix/profiles/home-manager)/activate | grep -A 10 "agenix"
```

### Run Activation with More Debug Info

```bash
# Enable bash debugging for activation
export VERBOSE=1
bash -x $(readlink /home/jan/.local/state/nix/profiles/home-manager)/activate 2>&1 | tee /tmp/hm-activation-debug.log
```

### Test Atuin Login Manually

```bash
# The atuin login now happens via ZSH initExtra
# To test manually:
atuinLogin

# Or check if already logged in:
atuin account verify && echo "✓ Logged in" || echo "✗ Not logged in"
```

## 5. Common Issues to Look For

### Issue: Home Key Not Available

The system-level key must be decrypted first before home-manager can decrypt user secrets.

Check:
```bash
# Verify the home key exists and has correct permissions
ls -la /run/agenix/agenix-home-key
# Should show: -r-------- 1 jan users ... /run/agenix/agenix-home-key

# If missing, check NixOS agenix service
systemctl status agenix.service
journalctl -u agenix.service -b
```

### Issue: Secrets Not Decrypted

Check:
```bash
# 1. Verify identity key is available
ls -la /run/agenix/agenix-home-key

# 2. Check if agenix service ran
systemctl --user status agenix.service

# 3. Verify secrets directory exists and has content
ls -la /run/user/$(id -u)/agenix/

# 4. Check home-manager knows about the identity
home-manager generations | head -n 1
readlink ~/.local/state/nix/profiles/home-manager
# Then check the activation script for identityPaths

# 5. Verify secret files exist in nix store
ls -la /nix/store/*atuin.age
```

### Issue: SSH Keys Not Loading

SSH keys are now managed by home-manager agenix, placed directly in ~/.ssh/

Check:
```bash
# Verify SSH key files exist
ls -la ~/.ssh/id_ed25519*

# Expected files:
# ~/.ssh/id_ed25519 (secret, from agenix)
# ~/.ssh/id_ed25519.pub (public key)
# ~/.ssh/id_ed25519-hetzner-sb (secret, from agenix)
# ~/.ssh/id_ed25519-hetzner-sb.pub (public key)
# ~/.ssh/id_ed25519-jabasoft-ug (secret, from agenix)
# ~/.ssh/id_ed25519-jabasoft-ug.pub (public key)

# Check permissions (should be 0400 or 0600)
stat -c '%a %n' ~/.ssh/id_ed25519*
```

### Issue: Atuin Not Logging In

Atuin login now happens via ZSH shell initialization, not activation hooks.

Check:
```bash
# 1. Verify atuin secret is decrypted
ls -la /run/user/$(id -u)/agenix/atuin

# 2. Test login manually
atuinLogin

# 3. Check if credentials are correct
source /run/user/$(id -u)/agenix/atuin
echo "User: $ATUIN_USER"  # Should show your username
echo "Key length: ${#ATUIN_KEY}"  # Should show a number

# 4. Check ZSH initialization includes atuinLogin
grep -r "atuinLogin" ~/.config/zsh/ ~/.zshrc 2>/dev/null
```

### Issue: Systemd Services Not Updated

```bash
# Check if daemon-reload happened
journalctl -u home-manager-jan.service -b | grep "daemon-reload"

# Manually reload
systemctl --user daemon-reload

# Check service file age
stat -c '%y %n' ~/.config/systemd/user/agenix.service
```

## 6. Useful Systemd Journal Commands

```bash
# Show only errors
journalctl -u home-manager-jan.service -p err -b

# Show with kernel messages (useful for boot issues)
journalctl -u home-manager-jan.service -b -k

# Export logs to file for analysis
journalctl -u home-manager-jan.service -b > /tmp/hm-activation.log

# Follow multiple services at once
journalctl -f -u home-manager-jan.service -u agenix.service --user
```

## 7. After Rebuild

After running `sudo nixos-rebuild switch --flake .#jabasoft-tx`, check:

```bash
# 1. Verify new generation was created
ls -la /nix/var/nix/profiles/system*-link | tail -n 3

# 2. Check if home-manager service ran
systemctl status home-manager-jan.service

# 3. Verify secrets are decrypted
ls -la /run/user/$(id -u)/agenix/

# 4. Check for atuin secret specifically
test -f /run/user/$(id -u)/agenix/atuin && echo "✓ atuin secret exists" || echo "✗ atuin secret missing"
```

## 8. Quick Troubleshooting Checklist

After reboot/login, run these commands in order:

```bash
# 1. Check system-level agenix (home key)
sudo ls -la /run/agenix/agenix-home-key
# Expected: -r-------- 1 jan users ... /run/agenix/agenix-home-key

# 2. Check home-manager service
systemctl status home-manager-jan.service

# 3. Check if it completed all activation steps
journalctl -u home-manager-jan.service -b | tail -n 30

# 4. Check user-level agenix service
systemctl --user status agenix.service

# 5. Verify all user secrets are decrypted
ls -la /run/user/$(id -u)/agenix/
# Expected: atuin, zsh-secrets, gpg-key-private.asc

# 6. Verify SSH keys
ls -la ~/.ssh/id_ed25519*

# 7. If secrets are missing, check agenix logs
journalctl --user -u agenix.service -b

# 8. Test atuin login
atuinLogin
```

## 9. Understanding the Secret Flow

```
Boot/Rebuild
    ↓
NixOS Activation
    ↓
System agenix decrypts: agenix-home-key.age
    → Output: /run/agenix/agenix-home-key (owned by user)
    ↓
Home-Manager Activation
    ↓
User agenix reads: /run/agenix/agenix-home-key
    ↓
User agenix decrypts user secrets:
    → /run/user/$(id -u)/agenix/atuin
    → /run/user/$(id -u)/agenix/zsh-secrets
    → /run/user/$(id -u)/agenix/gpg-key-private.asc
    → ~/.ssh/id_ed25519 (symlinked)
    → ~/.ssh/id_ed25519-hetzner-sb (symlinked)
    → ~/.ssh/id_ed25519-jabasoft-ug (symlinked)
    ↓
User logs in / Opens shell
    ↓
ZSH initExtra runs
    ↓
atuinLogin script executes
    → Reads /run/user/$(id -u)/agenix/atuin
    → Logs into Atuin if not already authenticated
```

## 10. Enable/Disable Verbose Logging

To enable verbose home-manager logging:

```nix
# In flake.nix, uncomment:
verbose = true;  # Enable verbose home-manager activation
```

To see verbose output:
- System activation: Check `/var/log/nixos/` or `journalctl -b`
- User activation: `journalctl -u home-manager-jan.service`

To disable:
```nix
# In flake.nix, comment out or set to false:
# verbose = true;
```
