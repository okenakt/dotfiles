#!/usr/bin/env bash
# Text-only network status: "NET: <SSID>" or "NET: <iface>" or "NET: offline"
ssid=""
if command -v iwgetid >/dev/null 2>&1; then
  ssid=$(iwgetid -r 2>/dev/null)
fi
if [ -n "$ssid" ]; then
  echo "NET: ${ssid}"
else
  iface=$(ip route get 1.1.1.1 2>/dev/null | awk '/dev/{print $5; exit}')
  if [ -n "$iface" ]; then
    echo "NET: ${iface}"
  else
    echo "NET: offline"
  fi
fi
