#!/usr/bin/env bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y docker.io
systemctl enable --now docker

docker volume create pmm-data
docker run --detach \
  --name pmm-server \
  --restart always \
  --publish 443:8443/tcp \
  --volume pmm-data:/srv \
  --env PMM_DATA_RETENTION=336h \
  --env PMM_ENABLE_UPDATES=0 \
  percona/pmm-server:3
