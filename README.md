## Load Test Toolbox (k6, hey)

This container provides two specialized load testing tools for different scenarios:

### **K6 - For Token-Based APIs with locking (Navitaire APIs)**
- **Use Case**: APIs that require authentication tokens with **locking constraints**
- **Problem Solved**: Navitaire API tokens cannot be used concurrently (token locking errors)
- **Solution**: Token pooling - each virtual user gets a unique token

### **Hey - For Non-Token APIs without locking (Redis Caching, etc.)**  
- **Use Case**: APIs without token-based locking (Redis, health checks, public endpoints)
- **Problem Solved**: Simple high-throughput testing without authentication complexity
- **Solution**: Direct concurrent requests without token concurrency issues

### Build

```bash
podman compose build
# or
podman build -t quay.io/balki404/load-test:latest -f Containerfile .
```

### Run with compose

Mount the project root into the container at `/work` (ensure payloads are under `payloads/`).

```bash
podman compose up --no-start
podman compose run --rm loadtest help
```

Available commands:

```bash
# K6 - Token-based API testing (Navitaire APIs)
podman compose run --rm loadtest run:k6

# Hey - Non-token API testing (Redis caching, etc.)
podman compose run --rm loadtest run:hey-caching
```

### Run directly

```bash
podman run --rm -it -v "$PWD:/work:Z" quay.io/balki404/load-test:latest help
```

## Usage Examples

### **K6 - Token-Based API Testing**

```bash
# Local K6 execution
k6 run --out json=logs/results.json loadtest.js

# K6 with custom configuration
k6 run \
  -e AUTH_URL=https://dotrezapi.test.6e.navitaire.com/api/nsk/v2/token \
  -e API_BASE=http://localhost:5237/checkin/v1/journeys/retrieve \
  -e TOKEN_POOL_SIZE=20 \
  -e VUS=20 \
  -e DURATION=120s \
  --out json=logs/results.json \
  loadtest.js

# K6 via container (Navitaire API example)
podman-compose run --rm \
  -e API_BASE=http://host.containers.internal:5237/checkin/v1/journeys/retrieve \
  -e VUS=11 \
  -e DURATION=30s \
  -e TOKEN_POOL_SIZE=11 \
  loadtest run:k6
```

### **Hey - Non-Token API Testing**

```bash
# Redis caching API testing
podman-compose run --rm \
  -e API_BASE=http://host.containers.internal:5231/api/v1/cache/getcache \
  -e CONCURRENCY=50 \
  -e DURATION=30s \
  loadtest run:hey-caching
```

## Environment Variables

### **K6 Configuration**
- `AUTH_URL` - Token authentication endpoint (default: Navitaire test API)
- `API_BASE` - Target API endpoint for load testing
- `TOKEN_POOL_SIZE` - Number of tokens to generate (should match or exceed VUS)
- `VUS` - Number of virtual users (concurrent connections)
- `DURATION` - Test duration (e.g., "60s", "5m")

### **Hey Configuration**  
- `API_BASE` - Target API endpoint (no authentication)
- `CONCURRENCY` - Number of concurrent requests
- `DURATION` - Test duration
- `METHOD` - HTTP method (GET, POST, etc.)

## Key Differences

| Feature | K6 | Hey |
|---------|----|----|
| **Authentication** | Token pooling (unique per VU) | No authentication |
| **Use Case** | Navitaire APIs with token locking | Redis, health checks, public APIs |
| **Concurrency** | True concurrent users | High-throughput requests |
| **Metrics** | Rich metrics, thresholds, percentiles | Simple throughput metrics |
| **Payloads** | Multiple JSON payloads (random selection) | Single endpoint testing |

## Notes

- Use `host.containers.internal` inside the container to reach services on the host
- Non-root UID 1001 is used
- Tools available: k6, hey

