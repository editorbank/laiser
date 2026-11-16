#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.properties"

IMAGE="${SERVICE_OWNER}/${SERVICE_NAME}:${SERVICE_VERSION}"

docker pull $IMAGE
