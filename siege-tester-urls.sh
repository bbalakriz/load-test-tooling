#!/usr/bin/env bash
set -euo pipefail

AUTH_URL="${AUTH_URL:-https://dotrezapi.test.6e.navitaire.com/api/nsk/v2/token}"
TMP_TOKEN_FILE="${TMP_TOKEN_FILE:-.token.json}"
URLS_FILE="${URLS_FILE:-urls.txt}"
RESULTS_FILE="${RESULTS_FILE:-logs/siege-results.log}"
API_BASE="${API_BASE:-http://localhost:5237/checkin/v1/journeys/retrieve}"
PAYLOAD_GLOB="${PAYLOAD_GLOB:-payloads/payload*.json}"
CONCURRENCY="${CONCURRENCY:-10}"
DURATION="${DURATION:-30s}"

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

# Step 2. Build urls.txt with inline JSON
echo "[INFO] Generating $URLS_FILE ..."
rm -f "$URLS_FILE"
shopt -s nullglob
found=false
for f in $PAYLOAD_GLOB; do
  found=true
  PAYLOAD=$(tr -d '\n' < "$f")
  echo "$API_BASE POST $PAYLOAD" >> "$URLS_FILE"
done
shopt -u nullglob
if [[ "$found" == false ]]; then
  echo "[WARN] No payloads found matching pattern: $PAYLOAD_GLOB"
fi
echo "[INFO] URLs file created with $(wc -l < $URLS_FILE) payloads."

# Step 3. Run siege test
echo "[INFO] Starting siege load test..."
siege -t"$DURATION" -c"$CONCURRENCY" \
  --header="Accept: application/json" \
  --header="Authorization: Bearer $TOKEN" \
  --header="Content-Type: application/json" \
  -f "$URLS_FILE" 2>&1 | tee "$RESULTS_FILE"

# Step 4. Extract benchmark stats
echo
echo "========== Benchmark Results =========="
grep -E "Transactions|Availability|Elapsed time|Data transferred|Response time|Transaction rate|Throughput|Concurrency|Successful transactions|Failed transactions" "$RESULTS_FILE"
echo "======================================="


