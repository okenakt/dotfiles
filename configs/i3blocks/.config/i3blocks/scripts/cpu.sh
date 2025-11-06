#!/usr/bin/env bash
# Text-only CPU usage: "CPU: 12.3%"
cpu_usage=$(grep -m1 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}')
printf "CPU: %.1f%%\n" "$cpu_usage"
