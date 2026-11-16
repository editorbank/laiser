#!/usr/bin/env bash
set -uo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"
MODEL="${MODEL:-qwen2.5-3b-instruct}"
PROMPT="${1:-Привет!}"
MAX_TOKENS="${MAX_TOKENS:-512}"

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
