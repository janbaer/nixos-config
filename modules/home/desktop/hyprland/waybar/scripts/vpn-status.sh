#!/usr/bin/env bash

disconnected() {
  icon=$(printf '\uf09c')
  printf '{"text": "%s", "tooltip": "No VPN connected", "class": "disconnected"}\n' "$icon"
}

vpn_connections=$(nmcli -t -f TYPE,NAME con show --active 2>/dev/null | grep -E '^(vpn|wireguard):' | cut -d: -f2)

if [ -n "$vpn_connections" ]; then
  names=$(echo "$vpn_connections" | paste -sd ", " -)
  icon=$(printf '\uf023')
  printf '{"text": "%s", "tooltip": "VPN active: %s", "class": "connected"}\n' "$icon" "$names"
else
  disconnected
fi
