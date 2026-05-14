#!/usr/bin/env bash

STATUS=$(warp-cli status 2>/dev/null)

if echo "$STATUS" | grep -q "Status update: Connected"; then
  warp-cli disconnect
  sleep 2
  notify-send "WARP" "Disconnected"
else
  warp-cli connect
  sleep 2
  notify-send "WARP" "Connected"
fi
