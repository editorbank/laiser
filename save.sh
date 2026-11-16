#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.properties"

IMAGE="${SERVICE_OWNER}/${SERVICE_NAME}:${SERVICE_VERSION}"
ARCHIVE="${SERVICE_NAME}.tar.gz"

echo "Save image ..."
[ -f "$SCRIPT_DIR/$ARCHIVE" ] || docker save "$IMAGE" | gzip > "$SCRIPT_DIR/$ARCHIVE"

echo "Done."