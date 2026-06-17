#!/usr/bin/env bash

# NixOS Package Channel Comparison Script
# Compares a package's version across the stable channel tip, the revision
# currently locked in flake.lock, and the unstable channel.
#
# Use it to decide when a package floated from unstable via an overlay has
# been backported to stable and the overlay can be removed.
#
# Usage: ./nixos-check-pkg-channels.sh [package-name]
#        (defaults to "noctalia-shell")

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PKG="${1:-noctalia-shell}"

cd "$(dirname "$0")"

# jq is needed to read flake.lock; fall back to a throwaway nix shell if absent.
# Array form so the multi-word fallback word-splits correctly when invoked.
JQ=(jq)
command -v jq >/dev/null 2>&1 || JQ=(nix run nixpkgs#jq --)

# Branch names come from flake.nix so this tracks whatever the flake pins.
STABLE_REF=$(grep -oP 'nixpkgs\.url\s*=\s*"github:NixOS/nixpkgs/\K[^"]+' flake.nix || true)
UNSTABLE_REF=$(grep -oP 'nixpkgs-unstable\.url\s*=\s*"github:NixOS/nixpkgs/\K[^"]+' flake.nix || true)

# Locked revisions come from flake.lock (what you actually build today).
# --no-update-lock-file keeps this diagnostic strictly read-only.
META=$(nix flake metadata --no-update-lock-file --json)
STABLE_REV=$(echo "$META" | "${JQ[@]}" -r '.locks.nodes.nixpkgs.locked.rev // empty')
UNSTABLE_REV=$(echo "$META" | "${JQ[@]}" -r '.locks.nodes."nixpkgs-unstable".locked.rev // empty')

# Resolve a package version from a nixpkgs ref, or "n/a" if it fails.
pkg_version() {
  local ref="$1"
  nix eval --raw "github:NixOS/nixpkgs/${ref}#${PKG}.version" 2>/dev/null || echo "n/a"
}

echo -e "${BLUE}Comparing '${PKG}' versions across channels...${NC}"
echo

STABLE_TIP_VER="n/a"
STABLE_LOCKED_VER="n/a"
UNSTABLE_VER="n/a"

if [[ -n "$STABLE_REF" ]]; then
  STABLE_TIP_VER=$(pkg_version "$STABLE_REF")
  echo -e "stable tip (${STABLE_REF}):   ${GREEN}${STABLE_TIP_VER}${NC}"
fi

if [[ -n "$STABLE_REV" ]]; then
  STABLE_LOCKED_VER=$(pkg_version "$STABLE_REV")
  echo -e "your locked stable pin:        ${STABLE_LOCKED_VER}  (${STABLE_REV:0:12})"
fi

if [[ -n "$UNSTABLE_REV" ]]; then
  UNSTABLE_VER=$(pkg_version "$UNSTABLE_REV")
  echo -e "unstable (locked):             ${YELLOW}${UNSTABLE_VER}${NC}  (${UNSTABLE_REV:0:12})"
elif [[ -n "$UNSTABLE_REF" ]]; then
  UNSTABLE_VER=$(pkg_version "$UNSTABLE_REF")
  echo -e "unstable tip (${UNSTABLE_REF}): ${YELLOW}${UNSTABLE_VER}${NC}"
fi

echo

# Verdict: has stable caught up with unstable?
if [[ "$STABLE_TIP_VER" == "n/a" || "$UNSTABLE_VER" == "n/a" ]]; then
  echo -e "${YELLOW}Could not compare (package missing in one channel).${NC}"
  exit 0
fi

if [[ "$STABLE_TIP_VER" == "$UNSTABLE_VER" ]]; then
  echo -e "${GREEN}✓ Stable matches unstable (${STABLE_TIP_VER}) — any overlay for '${PKG}' can be dropped.${NC}"
elif [[ "$(printf '%s\n%s' "$STABLE_TIP_VER" "$UNSTABLE_VER" | sort -V | tail -n1)" == "$STABLE_TIP_VER" ]]; then
  echo -e "${GREEN}✓ Stable (${STABLE_TIP_VER}) is ahead of unstable (${UNSTABLE_VER}).${NC}"
else
  echo -e "${YELLOW}⧗ Stable (${STABLE_TIP_VER}) is behind unstable (${UNSTABLE_VER}) — overlay still needed.${NC}"
fi
