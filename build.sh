#!/usr/bin/env bash
#build.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/config.properties"

IMAGE="${SERVICE_NAME}:${SERVICE_VERSION}"
CONTAINER="${SERVICE_NAME}"
BASE_URL="${BASE_URL:-http://localhost:${SERVICE_PORT}}"
MODEL="${MODEL:-${MODEL_ALIAS}}"

if docker image inspect "$IMAGE" >/dev/null 2>&1; then
    echo "Image $IMAGE already exists."
else
    echo "Build image $IMAGE ..."
    docker build -t "$IMAGE" \
        --build-arg "LLAMA_CPP_VERSION=${LLAMA_CPP_VERSION}" \
        --build-arg "MODEL_REPO=${MODEL_REPO}" \
        --build-arg "MODEL_FILE=${MODEL_FILE}" \
        --build-arg "MODEL_SHA256=${MODEL_SHA256}" \
        "$SCRIPT_DIR"
fi

if [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null)" = "true" ]; then
    echo "Container $CONTAINER already running"
else
    echo "Run container $CONTAINER ..."
    docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
    docker run -d -p "${SERVICE_PORT}:8080" --user "$TEST_USERID" --name "$CONTAINER" "$IMAGE"
fi

echo "Waiting for server ready ..."
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

echo "Testing ..."
BASE_URL="$BASE_URL" MODEL="$MODEL" "$SCRIPT_DIR/test.sh"

echo "Done."