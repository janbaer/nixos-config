#!/usr/bin/env bash

nixos-rebuild switch --use-remote-sudo --flake .

./nixos-reboot-required.sh
