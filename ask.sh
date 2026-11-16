#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/config.properties"

BASE_URL="${BASE_URL:-http://localhost:${SERVICE_PORT}}"
MODEL="${MODEL:-${MODEL_ALIAS}}"
PROMPT="${1:-Привет!}"
MAX_TOKENS="${MAX_TOKENS:-${MAX_TOKENS:-512}}"

echo Asking ...
payload=$(jq -n \
    --arg model "$MODEL" \
    --arg prompt "$PROMPT" \
    --argjson max_tokens "$MAX_TOKENS" \
    '{model: $model, messages: [{role: "user", content: $prompt}], max_tokens: $max_tokens, temperature: 0}')

if response=$(curl -fsS "$BASE_URL/v1/chat/completions" \
        -H 'Content-Type: application/json; charset=utf-8' \
        -d "$payload" \
        | jq '.choices[].message.content' \
        ); then
    echo -e $response
else
    echo FAIL
    exit 1
fi
