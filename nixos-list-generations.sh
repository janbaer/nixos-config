#!/usr/bin/env bash

# List all NixOS system generations/builds
# This script shows available system configurations that can be rolled back to

set -euo pipefail

echo "=== NixOS System Generations ==="
echo

# List system generations
if command -v nixos-rebuild >/dev/null 2>&1; then
  sudo nixos-rebuild list-generations
else
  echo "Error: nixos-rebuild command not found"
  echo "Make sure you're running this on a NixOS system"
  exit 1
fi

echo
echo "=== Current System Generation ==="
# Show current generation
current_gen=$(readlink /run/current-system)
if [ -n "$current_gen" ]; then
  echo "Current: $current_gen"
  echo "Hash: $(basename "$current_gen" | cut -d'-' -f1)"
else
  echo "Could not determine current generation"
fi

# Check if system needs reboot
echo
echo "=== System Status ==="
booted_gen=$(readlink /run/booted-system 2>/dev/null || echo "")
current_gen=$(readlink /run/current-system 2>/dev/null || echo "")

if [ -n "$booted_gen" ] && [ -n "$current_gen" ]; then
  if [ "$booted_gen" = "$current_gen" ]; then
    echo "✓ System is up to date (no reboot needed)"
  else
    echo "⚠ System needs reboot to apply latest changes"
    echo "  Booted:  $(basename "$booted_gen")"
    echo "  Current: $(basename "$current_gen")"
    
    # Show quick diff if nvd is available
    if command -v nvd >/dev/null 2>&1; then
      echo
      echo "=== Changes since last boot ==="
      nvd diff "$booted_gen" "$current_gen" 2>/dev/null || echo "Could not show diff"
    fi
  fi
else
  echo "Could not determine system status"
fi

echo
echo "=== Boot Entries ==="
# Show GRUB entries if available
if [ -f /boot/grub/grub.cfg ]; then
  grep "menuentry.*NixOS" /boot/grub/grub.cfg | head -10 | sed 's/menuentry /  /'
else
  echo "No GRUB configuration found"
fi

echo
echo "=== Usage Tips ==="
echo "• Compare generations: ./nix-generation-diff.sh <gen1> <gen2>"
echo "• Rollback: sudo nixos-rebuild switch --rollback"
