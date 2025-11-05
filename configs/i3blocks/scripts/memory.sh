#!/usr/bin/env bash
# Text-only memory usage: "MEM: 47%"
mem=$(free -m | awk '/Mem:/ {printf "%.0f", $3/$2*100}')
echo "MEM: ${mem}%"
