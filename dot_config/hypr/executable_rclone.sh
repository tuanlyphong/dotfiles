#!/bin/bash

SERVICE_NAME="rclone-mount.service"

# Check if the user-level systemd service is active
if systemctl --user is-active --quiet "$SERVICE_NAME"; then
  systemctl --user stop "$SERVICE_NAME"
  notify-send "unmounted."
else
  systemctl --user start "$SERVICE_NAME"
  notify-send "mounted."
fi
