#!/usr/bin/env bash

set -e

echo "=== Deleting old Docker versions ==="
OLD_PACKAGES=$(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc 2>/dev/null | cut -f1)

if [ -not -z "$OLD_PACKAGES" ]; then
    sudo apt remove -y $OLD_PACKAGES
else
    echo "No older versions of Docker were found"
fi

echo "=== Installing dependencies ==="
sudo apt update
sudo apt install -y ca-certificates curl

echo "=== Adding the official Docker GPG key ==="
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "=== Adding the official Docker GPG key ==="
CODENAME=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
ARCH=$(dpkg --print-architecture)

sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $CODENAME
Components: stable
Architectures: $ARCH
Signed-By: /etc/apt/keyrings/docker.asc
EOF

echo "=== Updating package indexes ==="
sudo apt update

echo "=== Installing the current version of Docker ==="
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "=== Creating a docker group ==="
groupadd docker || true
sudo usermod -aG docker vagrant
newgrp docker

echo "=== The installation has been completed successfully! ==="
echo "Checking the Docker operation status"
docker --version
docker compose version