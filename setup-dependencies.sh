#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "--- Updating package list and installing prerequisites ---"
sudo apt-get update
sudo apt-get install -y curl git

echo "--- Installing direnv ---"
sudo apt-get install -y direnv

echo "--- Hooking direnv into bash (~/.bashrc) ---"
# Check if the hook already exists to avoid duplicate entries
if ! grep -q 'eval "$(direnv hook bash)"' ~/.bashrc; then
    echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
    echo "✅ direnv hooked into ~/.bashrc"
else
    echo "ℹ️ direnv is already hooked in ~/.bashrc"
fi

echo "--- Installing devbox ---"
# Installs devbox system-wide using the official script
curl -fsSL https://get.jetpack.io/devbox | bash

echo ""
echo "--- ✅ Installation Complete! ---"
echo "To start using direnv in bash immediately, run: source ~/.bashrc"
