#!/bin/bash
apt-get update
apt-get install curl -y

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh
docker --version
