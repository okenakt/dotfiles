#!/usr/bin/env bash
# Compact net speed display (4 digits right-aligned)
# Icons:  (down)   (up)

IFACE=$(ip route get 8.8.8.8 2>/dev/null | awk '/dev/{print $5; exit}')

if [ -z "$IFACE" ]; then
  echo "  0K    0K"
  exit 0
fi

RXF="/tmp/i3blocks_rx_$IFACE"
TXF="/tmp/i3blocks_tx_$IFACE"

RX=$(cat /sys/class/net/$IFACE/statistics/rx_bytes 2>/dev/null)
TX=$(cat /sys/class/net/$IFACE/statistics/tx_bytes 2>/dev/null)

if [ -z "$RX" ] || [ -z "$TX" ]; then
  echo "  0K    0K"
  exit 0
fi

if [ ! -f "$RXF" ] || [ ! -f "$TXF" ]; then
  echo "$RX" > "$RXF"
  echo "$TX" > "$TXF"
  echo "  0K    0K"
  exit 0
fi

RXB=$(cat "$RXF")
TXB=$(cat "$TXF")
echo "$RX" > "$RXF"
echo "$TX" > "$TXF"

if [ "$RX" -lt "$RXB" ] || [ "$TX" -lt "$TXB" ]; then
  echo "  0K    0K"
  exit 0
fi

RXRATE=$(( (RX - RXB) / 1024 ))
TXRATE=$(( (TX - TXB) / 1024 ))

# Limit to 4-digit field width (right aligned, fixed width)
printf " %4dK   %4dK\n" "$RXRATE" "$TXRATE"
