#!/usr/bin/env bash

# NixOS Reboot Required Check Script
# Checks if a reboot is needed after system updates
# Works with both bare metal and LXC containers

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "Checking if reboot is required..."

# Detect if we're in a container
IS_CONTAINER=false
if [[ -f /.dockerenv ]] || [[ -f /run/.containerenv ]] || grep -q "container=lxc" /proc/1/environ 2>/dev/null || ! [[ -L /run/current-system/kernel ]]; then
  IS_CONTAINER=true
  echo -e "${BLUE}Container environment detected${NC}"
fi

if [[ "$IS_CONTAINER" == true ]]; then
  # In containers, focus on services and systemd units that need restart
  echo "Checking for services that need restart..."
  
  RESTART_NEEDED=false
  
  # Check if systemd itself needs restart (major updates)
  if systemctl is-active --quiet systemd-reboot-required.service 2>/dev/null; then
    echo -e "${YELLOW}systemd indicates restart needed${NC}"
    RESTART_NEEDED=true
  fi
  
  # Check for failed units that might indicate need for restart
  FAILED_UNITS=$(systemctl --failed --no-legend --quiet 2>/dev/null | wc -l || echo "0")
  if [[ $FAILED_UNITS -gt 0 ]]; then
    echo -e "${YELLOW}Found $FAILED_UNITS failed systemd units${NC}"
    RESTART_NEEDED=true
  fi
  
  # Check if major system components changed by comparing generation timestamps
  if [[ -d /nix/var/nix/profiles ]]; then
    CURRENT_GEN=$(readlink /nix/var/nix/profiles/system 2>/dev/null || echo "")
    if [[ -n "$CURRENT_GEN" ]]; then
      BOOT_TIME=$(stat -c %Y /proc/1 2>/dev/null || echo "0")
      GEN_TIME=$(stat -c %Y "$CURRENT_GEN" 2>/dev/null || echo "0")
      
      if [[ $GEN_TIME -gt $BOOT_TIME ]]; then
        echo -e "${YELLOW}System generation newer than container start time${NC}"
        RESTART_NEEDED=true
      fi
    fi
  fi
  
  # Check if major system components changed
  if [[ -f /run/nixos-container-restart-needed ]]; then
    echo -e "${YELLOW}Container restart flag found${NC}"
    RESTART_NEEDED=true
  fi
  
  if [[ "$RESTART_NEEDED" == true ]]; then
    echo -e "${RED}⚠ Container restart recommended${NC}"
    echo "Consider restarting the container or affected services."
    exit 1
  else
    echo -e "${GREEN}✓ No container restart needed${NC}"
    exit 0
  fi
  
else
  # Original bare metal logic
  # Get current running kernel version
  RUNNING_KERNEL=$(uname -r)
  
  # Get the kernel version from current system generation
  if [[ -L /run/current-system/kernel ]]; then
    SYSTEM_KERNEL_PATH=$(readlink /run/current-system/kernel)
    echo "Debug: Kernel path is: $SYSTEM_KERNEL_PATH"
    
    # Try multiple extraction methods
    SYSTEM_KERNEL=$(basename "$SYSTEM_KERNEL_PATH" | grep -o 'linux-[0-9]\+\.[0-9]\+[0-9a-z.-]*' || \
                   echo "$SYSTEM_KERNEL_PATH" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+[0-9a-z.-]*' || \
                   basename "$SYSTEM_KERNEL_PATH")
  else
    echo -e "${RED}Error: Cannot read system kernel path${NC}"
    exit 1
  fi
  
  echo "Running kernel: $RUNNING_KERNEL"
  echo "System kernel:  $SYSTEM_KERNEL"
  
  # Check if kernels match
  if [[ "$RUNNING_KERNEL" == *"$SYSTEM_KERNEL"* ]] || [[ "$SYSTEM_KERNEL" == *"$RUNNING_KERNEL"* ]]; then
    echo -e "${GREEN}✓ No reboot required${NC}"
    echo "Kernel versions match."
    exit 0
  else
    echo -e "${RED}⚠ Reboot required${NC}"
    echo "Kernel has been updated. Please reboot to use the new kernel."
    
    # Optional: Check for other indicators
    if systemctl is-active --quiet systemd-reboot-required.service 2>/dev/null; then
      echo -e "${YELLOW}Additional reboot indicators found.${NC}"
    fi
    
    exit 1
  fi
fi
