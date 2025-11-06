#!/usr/bin/env bash
# Text-only CPU temp: "TEMP: 62.0°C" or "TEMP: N/A"
if command -v sensors >/dev/null 2>&1; then
  line=$(sensors 2>/dev/null | awk '
    /Package id 0:/ {print $4; exit}
    /Tctl:/ {print $2; exit}
    /Tdie:/ {print $2; exit}
    /CPU Temperature:/ {print $3; exit}
  ')
  if [ -n "$line" ]; then
    echo "TEMP: ${line//+/}"
    exit 0
  fi
fi
if [ -r /sys/class/thermal/thermal_zone0/temp ]; then
  t=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
  if [ "$t" -gt 1000 ] 2>/dev/null; then
    printf "TEMP: %.1f°C\n" "$(echo "$t/1000" | bc -l)"
  else
    printf "TEMP: %s°C\n" "$t"
  fi
  exit 0
fi
echo "TEMP: N/A"
