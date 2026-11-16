#!/usr/bin/env bash
#load.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/config.properties"

IMAGE="${SERVICE_NAME}:${SERVICE_VERSION}"
CONTAINER="${SERVICE_NAME}"
ARCHIVE="$SCRIPT_DIR/${SERVICE_NAME}.tar.gz"
BASE_URL="${BASE_URL:-http://localhost:${SERVICE_PORT}}"

if docker image inspect "$IMAGE" >/dev/null 2>&1; then
    echo "Image $IMAGE already loaded"
elif [ -f "$ARCHIVE" ]; then
    docker load < "$ARCHIVE"
else
    echo "${SERVICE_NAME}.tar.gz not found and image $IMAGE is not loaded"
    exit 1
fi

if [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null)" = "true" ]; then
    echo "Container $CONTAINER already running"
else
    docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
    docker run -d -p "${SERVICE_PORT}:${SERVICE_PORT}" --user "$TEST_USERID" --name "$CONTAINER" "$IMAGE"
fi

echo "Waiting for server ..."
ready=0
for i in $(seq 1 30); do
    if curl -sf "${BASE_URL}/health" >/dev/null; then
        ready=1
        break
    fi
    sleep 1
done
if [ "$ready" -ne 1 ]; then
    echo "Server did not become ready within 30 seconds"
    exit 1
fi

echo "Loaded models:"
curl --compressed -fs "${BASE_URL}/v1/models" | jq -r '.data[].id // .models[].name'
