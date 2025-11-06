#!/usr/bin/env bash
# Text-only disk usage for / : "DISK: 63% (42G free)"
TARGET="/"
read -r _ size used avail usep _ <<<"$(df -hP "$TARGET" | awk 'NR==2{print $1,$2,$3,$4,$5,$6}')"
echo "DISK: ${usep} (${avail} free)"
