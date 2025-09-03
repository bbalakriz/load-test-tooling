#!/bin/bash
set -euo pipefail

API_BASE="${API_BASE:-http://localhost:5237/checkin/v1/journeys/retrieve}"
AUTH_URL="${AUTH_URL:-https://dotrezapi.test.6e.navitaire.com/api/nsk/v2/token}"
TMP_TOKEN_FILE="${TMP_TOKEN_FILE:-.token.json}"
RESULTS_FILE="${RESULTS_FILE:-logs/hey-results.log}"
PAYLOAD_GLOB="${PAYLOAD_GLOB:-payloads/payload*.json}"
CONCURRENCY="${CONCURRENCY:-10}"
DURATION="${DURATION:-2m}"
METHOD="${METHOD:-POST}"

mkdir -p "$(dirname "$RESULTS_FILE")"

# Step 1. Fetch token
echo "[INFO] Fetching API token..."
curl -s -X POST "$AUTH_URL" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{"applicationName": "mobile"}' > "$TMP_TOKEN_FILE"

TOKEN=$(jq -r '.data.token' "$TMP_TOKEN_FILE")

if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
  echo "[ERROR] Failed to fetch token"
  exit 1
fi
echo "[INFO] Token retrieved successfully."

# Step 2. Run hey for each payload
echo "[INFO] Starting hey tests..."
rm -f "$RESULTS_FILE"

shopt -s nullglob
found=false
for f in $PAYLOAD_GLOB; do
  found=true
  echo "[INFO] Testing $f ..."
  hey -z "$DURATION" -c "$CONCURRENCY" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -m "$METHOD" \
    -D "./$f" \
    "$API_BASE" 2>&1 | tee -a "$RESULTS_FILE"
  echo "----------------------------------------" >> "$RESULTS_FILE"
done
shopt -u nullglob

if [[ "$found" == false ]]; then
  echo "[WARN] No payloads found matching pattern: $PAYLOAD_GLOB"
fi

# Step 3. Extract benchmark stats
echo
echo "========== Benchmark Results =========="
grep -E "Total|Slowest|Fastest|Average|Requests/sec|Total data" "$RESULTS_FILE" || echo "[WARN] No benchmark stats found."
echo "======================================="


