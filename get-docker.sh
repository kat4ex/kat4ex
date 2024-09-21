#!/bin/bash
sudo apt-get update
sudo apt-get install curl -y

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh
docker --version

if command -v usermod >/dev/null 2>&1; then
  sudo usermod -aG docker $USER
fi