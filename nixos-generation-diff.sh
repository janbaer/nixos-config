#!/usr/bin/env bash

# Compare differences between NixOS generations
# Usage: ./generation-diff.sh [gen1] [gen2]
# If no arguments provided, compares current with previous generation

set -euo pipefail

show_usage() {
  echo "Usage: $0 [generation1] [generation2]"
  echo
  echo "Examples:"
  echo "  $0                    # Compare current with previous generation"
  echo "  $0 65 66             # Compare generation 65 with 66"
  echo "  $0 current previous  # Compare current with previous"
  echo "  $0 current booted    # Compare current with booted system"
  echo
  echo "Available generations:"
  if command -v nixos-rebuild >/dev/null 2>&1; then
    sudo nixos-rebuild list-generations | tail -5
  fi
}

get_generation_path() {
  local gen="$1"
  
  case "$gen" in
    "current")
      readlink /run/current-system 2>/dev/null || echo ""
      ;;
    "booted")
      readlink /run/booted-system 2>/dev/null || echo ""
      ;;
    "previous"|"prev")
      # Get previous generation from list
      local prev_num
      prev_num=$(sudo nixos-rebuild list-generations | tail -2 | head -1 | awk '{print $1}' 2>/dev/null || echo "")
      if [ -n "$prev_num" ]; then
        echo "/nix/var/nix/profiles/system-${prev_num}-link"
      fi
      ;;
    [0-9]*)
      # Numeric generation
      echo "/nix/var/nix/profiles/system-${gen}-link"
      ;;
    /*)
      # Full path
      echo "$gen"
      ;;
    *)
      echo ""
      ;;
  esac
}

compare_with_nvd() {
  local path1="$1"
  local path2="$2"
  
  echo "=== Using nvd tool ==="
  if nvd diff "$path1" "$path2" 2>/dev/null; then
    return 0
  else
    echo "nvd comparison failed, trying alternative methods..."
    return 1
  fi
}

compare_with_nix_store() {
  local path1="$1"
  local path2="$2"
  
  echo "=== Using nix store diff-closures ==="
  if nix store diff-closures "$path1" "$path2" 2>/dev/null; then
    return 0
  else
    echo "nix store diff-closures failed"
    return 1
  fi
}

compare_manual() {
  local path1="$1"
  local path2="$2"
  
  echo "=== Manual comparison ==="
  echo "Generation 1: $(basename "$path1")"
  echo "Generation 2: $(basename "$path2")"
  echo
  
  # Compare store paths
  echo "Store paths:"
  echo "  Path 1: $path1"
  echo "  Path 2: $path2"
  echo
  
  # Check if paths exist
  if [ ! -e "$path1" ]; then
    echo "Error: Path 1 does not exist: $path1"
    return 1
  fi
  
  if [ ! -e "$path2" ]; then
    echo "Error: Path 2 does not exist: $path2"
    return 1
  fi
  
  # Show basic info
  echo "Timestamps:"
  echo "  Path 1: $(ls -l "$path1" | awk '{print $6, $7, $8}')"
  echo "  Path 2: $(ls -l "$path2" | awk '{print $6, $7, $8}')"
  
  return 0
}

main() {
  # Check if running on NixOS
  if ! command -v nixos-rebuild >/dev/null 2>&1; then
    echo "Error: nixos-rebuild command not found"
    echo "Make sure you're running this on a NixOS system"
    exit 1
  fi
  
  # Parse arguments
  local gen1="${1:-current}"
  local gen2="${2:-previous}"
  
  if [ "$gen1" = "-h" ] || [ "$gen1" = "--help" ]; then
    show_usage
    exit 0
  fi
  
  # Get generation paths
  local path1
  local path2
  path1=$(get_generation_path "$gen1")
  path2=$(get_generation_path "$gen2")
  
  if [ -z "$path1" ]; then
    echo "Error: Could not determine path for generation '$gen1'"
    show_usage
    exit 1
  fi
  
  if [ -z "$path2" ]; then
    echo "Error: Could not determine path for generation '$gen2'"
    show_usage
    exit 1
  fi
  
  echo "Comparing NixOS generations:"
  echo "  From: $(basename "$path1") -> $path1"
  echo "  To:   $(basename "$path2") -> $path2"
  echo
  
  # Try different comparison methods
  if command -v nvd >/dev/null 2>&1; then
    if compare_with_nvd "$path1" "$path2"; then
      exit 0
    fi
  fi
  
  if command -v nix >/dev/null 2>&1; then
    if compare_with_nix_store "$path1" "$path2"; then
      exit 0
    fi
  fi
  
  # Fallback to manual comparison
  compare_manual "$path1" "$path2"
  
  echo
  echo "Tip: Install nvd for better diff output: ./install-nvd.sh"
}

main "$@"