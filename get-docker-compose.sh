#!/bin/bash

curl -L https://github.com/docker/compose/releases/download/v2.32.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose	
docker-compose --version
