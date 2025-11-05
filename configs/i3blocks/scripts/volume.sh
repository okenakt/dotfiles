#!/usr/bin/env bash
# Text-only volume: "VOL: 55%" or "VOL: MUTE"
if command -v pamixer >/dev/null 2>&1; then
  vol=$(pamixer --get-volume 2>/dev/null)
  mute=$(pamixer --get-mute 2>/dev/null)
  if [ "$mute" = "true" ]; then
    echo "VOL: MUTE"
  else
    echo "VOL: ${vol}%"
  fi
else
  line=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | head -n1)
  mute=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{print $2}')
  vol=$(echo "$line" | grep -oE '[0-9]+%' | head -n1)
  if [ "$mute" = "yes" ]; then
    echo "VOL: MUTE"
  else
    echo "VOL: ${vol}"
  fi
fi
