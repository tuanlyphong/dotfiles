#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=========================================="
echo "🚀 Starting System Post-Installation Script"
echo "=========================================="

# 1. Sync pacman databases and install packages from your list
if [ -f "$HOME/.pkglist" ]; then
  echo "📦 Package list found. Syncing databases and installing applications..."
  sudo pacman -Sy --needed --noconfirm - <"$HOME/.pkglist"
else
  echo "⚠️ Warning: $HOME/.pkglist not found! Skipping package installation."
fi

# 2. Enable your exact required system services
echo "⚙️ Enabling system background services..."
sudo systemctl enable NetworkManager \
  nvidia-hibernate \
  nvidia-resume \
  nvidia-suspend \
  power-profiles-daemon \
  sddm \
  systemd-timesyncd \
  warp-svc

echo "✅ System bootstrap complete! Your configs, packages, and services match."
