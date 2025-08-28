#!/bin/bash
set -e

API_BASE="http://localhost:5237/checkin/v1/journeys/retrieve"
AUTH_URL="https://dotrezapi.test.6e.navitaire.com/api/nsk/v2/token"
TMP_TOKEN_FILE=".token.json"
RESULTS_FILE="siege-results.log"

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

# Step 2. Run siege for each payload
echo "[INFO] Starting siege tests..."
rm -f "$RESULTS_FILE"

for f in payload*.json; do
  echo "[INFO] Testing $f ..."
  siege -c40 -r3 \
    --header="Accept: application/json" \
    --header="Authorization: Bearer $TOKEN" \
    --header="Content-Type: application/json" \
    "$API_BASE POST <$f" 2>&1 | tee -a "$RESULTS_FILE"
done

# Step 3. Extract benchmark stats
echo
echo "========== Benchmark Results =========="
grep -E "Transactions|Availability|Elapsed time|Data transferred|Response time|Transaction rate|Throughput|Concurrency|Successful transactions|Failed transactions" "$RESULTS_FILE" || echo "[WARN] No benchmark stats found."
echo "======================================="

