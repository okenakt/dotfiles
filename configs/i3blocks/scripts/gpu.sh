#!/usr/bin/env bash
# Text-only GPU status: "GPU: 45% 1234/8192MiB" or "GPU: 45%" or "GPU: N/A"

# NVIDIA
if command -v nvidia-smi >/dev/null 2>&1; then
  util=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1)
  read -r used total <<<"$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | head -n1 | awk -F',' '{gsub(/ /,""); print $1,$2}')"
  if [ -n "$util" ]; then
    if [ -n "$total" ]; then
      echo "GPU: ${util}% ${used}/${total}MiB"
    else
      echo "GPU: ${util}%"
    fi
    exit 0
  fi
fi

echo "GPU: N/A"
