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
# The Microsoft Python devcontainer image ships /etc/apt/sources.list.d/yarn.list
# with a yarn repo whose signing key Debian can't verify, so a fresh apt-get
# update exits 100 and (under set -e) aborts the whole postCreate chain. We
# don't need yarn for anything here, so drop the source before updating.
sudo rm -f /etc/apt/sources.list.d/yarn.list
sudo apt-get update
sudo apt-get install -y openssh-server
# sshd looks for /run/sshd, not /var/run/sshd — the /var/run -> /run symlink
# isn't set up before systemd is installed, so the two are distinct paths
# at this point in the build. Create the actual directory sshd opens.
sudo mkdir -p /run/sshd
sudo ssh-keygen -A
sudo /usr/sbin/sshd
echo "openssh-server running."

# Trust the AGA Bolt proxy's self-signed cert so the Neo4j Python driver
# (`bolt+s://session-…`) accepts TLS connections to it without the lesson
# code needing to pass any custom driver options. This is a TESTING-only
# block: it bakes a dev-only CA into the Codespace. For production the
# Bolt proxy uses a publicly-issued cert and this whole step is unnecessary.
if [ -f .devcontainer/aga-bolt-proxy.crt ]; then
    echo "Installing AGA Bolt proxy CA..."
    sudo cp .devcontainer/aga-bolt-proxy.crt /usr/local/share/ca-certificates/aga-bolt-proxy.crt
    sudo update-ca-certificates
    echo "AGA Bolt proxy CA installed."
fi

echo ""
echo "Dependencies installed."
