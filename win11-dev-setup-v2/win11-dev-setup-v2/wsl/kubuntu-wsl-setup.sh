#!/usr/bin/env bash
set -euo pipefail

# Enable systemd in WSL if not already
if [ ! -f /etc/wsl.conf ] || ! grep -q "systemd=true" /etc/wsl.conf; then
  echo "Configuring /etc/wsl.conf for systemd..."
  sudo tee /etc/wsl.conf >/dev/null <<'EOF'
[boot]
systemd=true
[user]
default=${USER}
EOF
  echo "Now exit WSL and run:  wsl --shutdown"
fi

sudo apt-get update
# Lightweight Plasma (avoid full kubuntu-desktop bloat)
sudo apt-get install -y kde-plasma-desktop sddm konsole dolphin kate okular \
  plasma-discover plasma-discover-backend-flatpak flatpak

# Optional: VS Code server deps, graphics bits
sudo apt-get install -y mesa-utils dbus-x11

echo "KDE Plasma installed for WSL. Restart WSL (wsl --shutdown) and launch GUI apps (e.g., 'kate')."
