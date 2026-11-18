#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.properties"

IMAGE="${IMAGE_HUB}/${SERVICE_OWNER}/${SERVICE_NAME}:${SERVICE_VERSION}"

if docker image inspect "$IMAGE" ;then
  printenv DOCKER_PASS | docker login ${IMAGE_HUB} -u ${SERVICE_OWNER} --password-stdin && \
  docker push $IMAGE
fi
