#!/usr/bin/env bash

CONNECTION="wg0"

if nmcli -t -f NAME con show --active 2>/dev/null | grep -q "^${CONNECTION}$"; then
  nmcli con down "$CONNECTION" 2>/dev/null
else
  nmcli con up "$CONNECTION" 2>/dev/null
fi
