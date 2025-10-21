#!/usr/bin/env bash
set -euo pipefail
sudo apt-get update
sudo apt-get -y upgrade

# Base dev
sudo apt-get install -y build-essential git curl wget unzip zip ca-certificates pkg-config \
    ninja-build cmake clang llvm lld gdb ripgrep fd-find fzf

# Python
sudo apt-get install -y python3 python3-venv python3-pip
python3 -m pip install --user pipx
python3 -m pipx ensurepath

# Node (via corepack)
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi
corepack enable

# Docker CLI (optional; Docker Desktop provides daemon on Windows host)
sudo apt-get install -y docker.io
sudo usermod -aG docker "$USER" || true

echo "Ubuntu bootstrap complete. Restart shell to load pipx PATH."
