#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/config.properties"

IMAGE="${SERVICE_NAME}:${SERVICE_VERSION}"
CONTAINER="${SERVICE_NAME}"
ARCHIVE="$SCRIPT_DIR/${SERVICE_NAME}.tar.gz"

docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
docker rmi -f "$IMAGE" >/dev/null 2>&1 || true
[ -f "$ARCHIVE" ] && rm -f "$ARCHIVE" || true