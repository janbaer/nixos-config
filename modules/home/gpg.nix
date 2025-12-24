{ config, lib, pkgs, hostname, username, ... }:
with lib;
let
  inherit
    (import ./../../hosts/${hostname}/variables.nix)
    gpgKey
    gpgSshKeys
    ;
  cfg = config.modules.gpg;

  keychain = pkgs.keychain.overrideAttrs {
    version = "2.9.5";
    src = pkgs.fetchurl {
      url = "https://github.com/funtoo/keychain/archive/refs/tags/2.9.5.tar.gz";
      hash = "sha256-yIPybbYWvByBul7zgyx62RLz6L0Lr2qv+YEWTFOKFBE=";
    };
  };

  gpgSshKeygrips = builtins.concatStringsSep " " gpgSshKeys;

  gpgUnlockAllSshKeys = pkgs.writeShellScriptBin "gpgUnlockAllSshKeys" ''
    SSH_KEYGRIPS="${gpgSshKeygrips}"
    PRESET_TOOL="${pkgs.gnupg}/libexec/gpg-preset-passphrase"

    # Function to count uncached keys
    count_uncached() {
      local uncached=0
      for keygrip in $SSH_KEYGRIPS; do
        status=$(${pkgs.gnupg}/bin/gpg-connect-agent "keyinfo $keygrip" /bye 2>/dev/null | grep KEYINFO)
        cached=$(echo "$status" | awk '{print $7}')
        [ "$cached" != "1" ] && ((uncached++))
      done
      echo $uncached
    }

    # Handle --status flag (silent check, returns uncached count)
    if [ "$1" = "--status" ]; then
      uncached=$(count_uncached)
      exit $uncached
    fi

    echo "GPG SSH Keys Unlock Script"
    echo "=========================="
    echo ""
    echo "This will cache your GPG passphrase for all SSH subkeys."
    echo ""

    # Check current cache status
    echo "Current cache status:"
    for keygrip in $SSH_KEYGRIPS; do
      status=$(${pkgs.gnupg}/bin/gpg-connect-agent "keyinfo $keygrip" /bye 2>/dev/null | grep KEYINFO)
      cached=$(echo "$status" | awk '{print $7}')
      if [ "$cached" = "1" ]; then
        echo "  ✓ $keygrip (cached)"
      else
        echo "  ✗ $keygrip (not cached)"
      fi
    done
    echo ""

    # Ask for passphrase
    passphrase=$(systemd-ask-password "Enter GPG passphrase to unlock all SSH keys:")
    if [ -z "$passphrase" ]; then
      echo "✗ Error: No passphrase provided."
      exit 1
    fi

    # Preset passphrase for all SSH keygrips
    success=0
    failed=0

    echo "Unlocking SSH keys..."
    for keygrip in $SSH_KEYGRIPS; do
      if echo "$passphrase" | "$PRESET_TOOL" --preset "$keygrip" 2>/dev/null; then
        echo "  ✓ Unlocked: $keygrip"
        ((success++))
      else
        echo "  ✗ Failed:   $keygrip"
        ((failed++))
      fi
    done

    echo ""
    echo "Done: $success unlocked, $failed failed"

    if [ $failed -gt 0 ]; then
      echo ""
      echo "Note: Failures may indicate wrong passphrase or keys not yet imported."
      exit 1
    fi
  '';

  gpgImportKeys = pkgs.writeShellScriptBin "gpgImportKeys" ''
    echo "GPG Key Import Script"
    echo "====================="
    echo ""

    if ${pkgs.gnupg}/bin/gpg --list-keys --keyid-format short | grep -q "${gpgKey}"; then
      echo "✓ GPG key ${gpgKey} is already imported."
      exit 0
    fi

    PRIVATE_KEY_PATH="${config.age.secrets."gpg-key-private.asc".path}"
    PUBLIC_KEY_PATH="$HOME/.gnupg/gpg-key-public.asc"

    if [ ! -f "$PRIVATE_KEY_PATH" ]; then
      echo "✗ Error: Private key file not found at $PRIVATE_KEY_PATH"
      echo "  Make sure agenix secrets are deployed first."
      exit 1
    fi

    if [ ! -f "$PUBLIC_KEY_PATH" ]; then
      echo "✗ Error: Public key file not found at $PUBLIC_KEY_PATH"
      exit 1
    fi

    echo "Found GPG key files:"
    echo "  Private: $PRIVATE_KEY_PATH"
    echo "  Public:  $PUBLIC_KEY_PATH"
    echo ""

    gpg_passphrase=$(systemd-ask-password "Please enter the passphrase for your GPG private key:")
    if [ -z "$gpg_passphrase" ]; then
      echo "✗ Error: No passphrase provided."
      exit 1
    fi

    echo "Importing private key..."
    if echo "$gpg_passphrase" | ${pkgs.gnupg}/bin/gpg --batch --passphrase-fd 0 --import "$PRIVATE_KEY_PATH" 2>/dev/null; then
      echo "✓ Private key imported successfully"
    else
      echo "✗ Failed to import private key. Check your passphrase."
      exit 1
    fi

    echo "Importing public key..."
    if ${pkgs.gnupg}/bin/gpg --batch --import "$PUBLIC_KEY_PATH" 2>/dev/null; then
      echo "✓ Public key imported successfully"
    else
      echo "✗ Failed to import public key."
      exit 1
    fi

    echo ""
    echo "✓ GPG keys imported successfully!"
    echo ""
    echo "Imported keys:"
    ${pkgs.gnupg}/bin/gpg --list-keys --keyid-format short "${gpgKey}"
  '';
in {
  options.modules.gpg.enable = mkEnableOption "Configuration of GPG";

  config = mkIf cfg.enable {
    home.sessionVariables = {
      GPGKEY = gpgKey;
      GPG_TTY = "$(tty)";
    };

    home.packages = with pkgs; [
      seahorse              # Application for managing encryption keys and passwords in the GnomeKeyring
      keychain              # Keychain management tool for SSH and GPG keys
      gpgImportKeys         # Manual script to import GPG keys
      gpgUnlockAllSshKeys   # Script to unlock all SSH subkeys at once
    ];

    programs.gpg = { enable = true; };

    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      enableZshIntegration = true;
      defaultCacheTtl = 604800; # 7 days
      defaultCacheTtlSsh = 604800; # 7 days
      maxCacheTtl = 604800; # 7 days
      maxCacheTtlSsh = 604800; # 7 days
      pinentry.package = pkgs.pinentry-rofi;
      extraConfig = ''
        allow-preset-passphrase
      '';
      sshKeys = gpgSshKeys;
    };

    age.secrets."gpg-key-private.asc".file = ./../../secrets/gpg-key-private.age;
    home.file = {
      ".gnupg/gpg-key-public.asc".text = builtins.readFile ./../../secrets/gpg-key-public.asc;
    };
  };
}
