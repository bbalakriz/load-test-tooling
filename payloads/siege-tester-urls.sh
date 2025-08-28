#!/usr/bin/env bash
set -euo pipefail

AUTH_URL="https://dotrezapi.test.6e.navitaire.com/api/nsk/v2/token"
TMP_TOKEN_FILE=".token.json"
URLS_FILE="urls.txt"
RESULTS_FILE="siege-results.log"
API_BASE="http://localhost:5237/checkin/v1/journeys/retrieve"

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
for f in payload*.json; do
  PAYLOAD=$(tr -d '\n' < "$f")   # flatten JSON to one line
  echo "$API_BASE POST $PAYLOAD" >> "$URLS_FILE"
done
echo "[INFO] URLs file created with $(wc -l < $URLS_FILE) payloads."

# Step 3. Run siege test
echo "[INFO] Starting siege load test..."
siege -t30s -c40 \
  --header="Accept: application/json" \
  --header="Authorization: Bearer $TOKEN" \
  --header="Content-Type: application/json" \
  -f "$URLS_FILE" 2>&1 | tee "$RESULTS_FILE"  
  # -f "$URLS_FILE" \
  # --log="siege-requests.log" 2>&1 | tee "$RESULTS_FILE"


# Step 4. Extract benchmark stats
echo
echo "========== Benchmark Results =========="
grep -E "Transactions|Availability|Elapsed time|Data transferred|Response time|Transaction rate|Throughput|Concurrency|Successful transactions|Failed transactions" "$RESULTS_FILE"
echo "======================================="

# # Step 5. Extract response times and compute percentiles
# awk '{print $11}' siege-requests.log | grep -Eo '[0-9]+\.[0-9]+' > latencies.txt

# python3 <<'EOF'
# import numpy as np
# latencies = np.loadtxt("latencies.txt")
# percentiles = [10, 25, 50, 75, 90, 95, 99]
# for p in percentiles:
#     print(f"{p}th percentile: {np.percentile(latencies, p):.4f}s")
# EOF