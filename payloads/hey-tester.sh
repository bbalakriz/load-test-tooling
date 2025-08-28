#!/bin/bash
set -e

API_BASE="http://localhost:5237/checkin/v1/journeys/retrieve"
AUTH_URL="https://dotrezapi.test.6e.navitaire.com/api/nsk/v2/token"
TMP_TOKEN_FILE=".token.json"
RESULTS_FILE="hey-results.log"

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

for f in payload*.json; do
  echo "[INFO] Testing $f ..."
  # Using hey with similar parameters to siege (c1 -r10 = 10 requests total)
  # -n: number of requests, -c: number of concurrent requests

  # Steady traffic for 5 minutes, 100 concurrent users: hey -z 5m -c 100 -q 20
  # Burst test (10k total requests, 200 users): hey -n 10000 -c 200 -q 20
  # -q 20 means each worker sends 20 req/s
  hey -z 2m -c 10 \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -m POST \
    -D "./$f" \
    "$API_BASE" 2>&1 | tee -a "$RESULTS_FILE"
  
  # Add a separator between tests
  echo "----------------------------------------" >> "$RESULTS_FILE"
done

# Step 3. Extract benchmark stats
echo
echo "========== Benchmark Results =========="
grep -E "Total|Slowest|Fastest|Average|Requests/sec|Total data" "$RESULTS_FILE" || echo "[WARN] No benchmark stats found."
echo "======================================="
