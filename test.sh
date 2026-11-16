#!/usr/bin/env bash
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.properties"

BASE_URL="${BASE_URL:-http://127.0.0.1:${SERVICE_PORT}}"
MODEL="${MODEL:-${MODEL_ALIAS}}"
CONTAINER="${CONTAINER:-}"
WAIT_SECONDS="${WAIT_SECONDS:-0}"
MAX_TIME="${MAX_TIME:-180}"

FAILURES=0

usage() {
    printf 'Usage: %s [-u BASE_URL] [-m MODEL] [-c CONTAINER] [-w WAIT_SECONDS]\n' "$0"
    printf '  -u  service URL (default: %s)\n' "$BASE_URL"
    printf '  -m  model id (default: %s)\n' "$MODEL"
    printf '  -c  run checks inside container via docker exec (needed with --network none)\n'
    printf '  -w  wait up to N seconds for /health before testing (default: 0)\n'
}

while getopts ':u:m:c:w:h' opt; do
    case "$opt" in
        u) BASE_URL="$OPTARG" ;;
        m) MODEL="$OPTARG" ;;
        c) CONTAINER="$OPTARG" ;;
        w) WAIT_SECONDS="$OPTARG" ;;
        h) usage; exit 0 ;;
        *) usage; exit 2 ;;
    esac
done

if [[ -n "$CONTAINER" ]]; then
    command -v docker >/dev/null 2>&1 || { printf 'docker not found\n'; exit 2; }
    docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null | grep -q true \
        || { printf 'container %s is not running\n' "$CONTAINER"; exit 2; }
    curl_cmd() { docker exec -i "$CONTAINER" curl "$@"; }
else
    command -v curl >/dev/null 2>&1 || { printf 'curl not found\n'; exit 2; }
    curl_cmd() { curl "$@"; }
fi

pass() { printf '  [PASS] %s\n' "$1"; }
fail() { printf '  [FAIL] %s\n' "$1"; FAILURES=$((FAILURES + 1)); }

HTTP_CODE=""
HTTP_BODY=""

request() {
    local path="$1" data="${2:-}" out
    local -a args=(-sS --connect-timeout 5 --max-time "$MAX_TIME" -w $'\n%{http_code}' "$BASE_URL$path")
    [[ -n "$data" ]] && args+=(-H 'Content-Type: application/json' -d "$data")
    out="$(curl_cmd "${args[@]}")" || { HTTP_CODE="000"; HTTP_BODY=""; return 1; }
    HTTP_CODE="${out##*$'\n'}"
    HTTP_BODY="${out%$'\n'*}"
}

printf 'Testing %s (model: %s)\n' "$BASE_URL" "$MODEL"

if [[ "$WAIT_SECONDS" -gt 0 ]]; then
    printf 'Waiting for service'
    ready=0
    for ((i = 1; i <= WAIT_SECONDS; i++)); do
        request /health >/dev/null 2>&1
        if [[ "$HTTP_CODE" == "200" ]]; then ready=1; break; fi
        printf '.'
        sleep 1
    done
    printf '\n'
    if [[ "$ready" != "1" ]]; then
        printf '  [FAIL] service did not become healthy within %ss\n' "$WAIT_SECONDS"
        exit 1
    fi
fi

if request /health; then
    if [[ "$HTTP_CODE" == "200" ]]; then pass "GET /health -> 200"; else fail "GET /health -> $HTTP_CODE"; fi
else
    fail "GET /health -> connection error"
fi

if request /v1/models; then
    if [[ "$HTTP_CODE" != "200" ]]; then
        fail "GET /v1/models -> $HTTP_CODE"
    elif printf '%s' "$HTTP_BODY" | grep -Fq "\"id\":\"$MODEL\""; then
        pass "GET /v1/models contains '$MODEL'"
    else
        fail "GET /v1/models does not contain '$MODEL'"
    fi
else
    fail "GET /v1/models -> connection error"
fi

payload=$(printf '{"model":"%s","messages":[{"role":"user","content":"Reply with exactly: OK"}],"max_tokens":16,"temperature":0}' "$MODEL")

if request /v1/chat/completions "$payload"; then
    if [[ "$HTTP_CODE" != "200" ]]; then
        fail "POST /v1/chat/completions -> $HTTP_CODE"
    elif ! printf '%s' "$HTTP_BODY" | grep -Fq '"object":"chat.completion"'; then
        fail "POST /v1/chat/completions -> unexpected response"
    elif printf '%s' "$HTTP_BODY" | grep -Fq '"content":"OK"'; then
        pass "POST /v1/chat/completions -> completion 'OK'"
    else
        fail "POST /v1/chat/completions -> completion does not contain 'OK'"
    fi
else
    fail "POST /v1/chat/completions -> connection error"
fi

if [[ -n "$CONTAINER" ]]; then
    netmode="$(docker inspect -f '{{.HostConfig.NetworkMode}}' "$CONTAINER")"
    if [[ "$netmode" == "none" ]]; then
        pass "container network mode is 'none' (offline)"
    else
        printf '  [INFO] container network mode is %s\n' "$netmode"
    fi
fi

if [[ "$FAILURES" -eq 0 ]]; then
    printf 'All checks passed.\n'
    exit 0
fi

printf 'Failed checks: %d\n' "$FAILURES"
exit 1
