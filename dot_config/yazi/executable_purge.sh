#!/usr/bin/env bash
MOUNT="$HOME/mnt/gdrive1"
REMOTE="gdrive1:"

for path in "$@"; do
  rel="${path#$MOUNT/}"
  if [ -d "$path" ]; then
    rclone purge "$REMOTE$rel" --drive-use-trash=false
  else
    rclone deletefile "$REMOTE$rel" --drive-use-trash=false
  fi
done
