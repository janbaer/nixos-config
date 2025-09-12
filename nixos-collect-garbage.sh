#!/usr/bin/env bash

num_days="${1:-3}"

echo "Deleting all generations older than $num_days days..."
sudo nix-collect-garbage --delete-older-than ${num_days}d
