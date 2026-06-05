#!/usr/bin/env bash
set -euo pipefail

echo "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Install openssh-server so `gh codespace ssh` (and -R reverse port-forwards)
# work against this Codespace. This is only needed while the AGA proxy is
# served from a local dev laptop — once the proxy has a publicly reachable
# URL, this block can be removed. We install via plain apt rather than the
# `ghcr.io/devcontainers/features/sshd` feature because that feature breaks
# the devcontainer build on the Microsoft Python image (Error 1302).
echo "Installing openssh-server..."
sudo apt-get update -qq
sudo apt-get install -y -qq openssh-server
sudo mkdir -p /var/run/sshd
sudo ssh-keygen -A
sudo /usr/sbin/sshd
echo "openssh-server running."

echo ""
echo "Dependencies installed."
