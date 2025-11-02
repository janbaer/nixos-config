#!/usr/bin/env bash
#
# Verbose NixOS rebuild script with detailed logging
#
set -e

FLAKE=".#jabasoft-tx"
LOGFILE="/tmp/nixos-rebuild-$(date +%Y%m%d-%H%M%S).log"

echo "========================================"
echo "NixOS Rebuild with Verbose Logging"
echo "========================================"
echo "Flake: $FLAKE"
echo "Log file: $LOGFILE"
echo ""

# Function to show what flags do
show_flags() {
    echo "Using the following flags:"
    echo "  --show-trace    : Show detailed stack traces for evaluation errors"
    echo "  --verbose       : Enable verbose build output"
    echo "  --print-build-logs : Show build logs for failed builds"
    echo "  -L              : Print build logs during build (real-time)"
    echo ""
}

show_flags

echo "Starting rebuild at $(date)"
echo ""

# Run rebuild with verbose flags and capture output
sudo nixos-rebuild switch \
    --flake "$FLAKE" \
    --show-trace \
    --verbose \
    --print-build-logs \
    -L \
    2>&1 | tee "$LOGFILE"

EXIT_CODE=${PIPESTATUS[0]}

echo ""
echo "========================================"
if [ $EXIT_CODE -eq 0 ]; then
    echo "✓ Rebuild completed successfully!"
    echo ""
    echo "Checking agenix secrets..."
    echo ""
    echo "Available secrets in /run/user/$(id -u)/agenix:"
    ls -la /run/user/$(id -u)/agenix/ 2>&1 || echo "  (directory not found or empty)"
else
    echo "✗ Rebuild failed with exit code: $EXIT_CODE"
    echo ""
    echo "Check the log file for details: $LOGFILE"
    echo ""
    echo "Last 50 lines of output:"
    tail -n 50 "$LOGFILE"
fi
echo "========================================"

exit $EXIT_CODE
