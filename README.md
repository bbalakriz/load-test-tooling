## Load Test Toolbox (k6, siege, hey)

This container bundles k6, siege, and hey and provides wrappers to run your existing payloads and scripts.

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

Entry commands:

```bash
podman compose run --rm loadtest run:siege
podman compose run --rm loadtest run:siege-urls
podman compose run --rm loadtest run:hey
podman compose run --rm loadtest run:hey-caching
podman compose run --rm loadtest run:k6
```

### Run directly

```bash
podman run --rm -it -v "$PWD:/work:Z" quay.io/balki404/load-test:latest help
```

Examples:

```bash
podman run --rm -it -v "$PWD:/work:Z" -e API_BASE=http://host.containers.internal:5237/checkin/v1/journeys/retrieve quay.io/balki404/load-test:latest run:siege
podman run --rm -it -v "$PWD:/work:Z" -e API_BASE=http://host.containers.internal:5237/checkin/v1/journeys/retrieve quay.io/balki404/load-test:latest run:siege-urls
podman run --rm -it -v "$PWD:/work:Z" -e API_BASE=http://host.containers.internal:5237/checkin/v1/journeys/retrieve quay.io/balki404/load-test:latest run:hey
podman run --rm -it -v "$PWD:/work:Z" -e API_BASE=http://host.containers.internal:5237/checkin/v1/journeys/retrieve quay.io/balki404/load-test:latest run:k6
podman run --rm -it -v "$PWD:/work:Z" -e API_BASE=http://host.containers.internal:5237/checkin/v1/journeys/retrieve quay.io/balki404/load-test:latest run:hey-caching
```

### Environment overrides

Supported vars:

- API_BASE, AUTH_URL
- TMP_TOKEN_FILE, RESULTS_FILE
- PAYLOAD_GLOB, CONCURRENCY, DURATION, METHOD
- SIEGE_CONCURRENCY, SIEGE_REPEATS

Example:

```bash
podman compose run --rm \
  -e API_BASE=http://host.containers.internal:5237/checkin/v1/journeys/retrieve \
  -e CONCURRENCY=10 -e DURATION=20s loadtest run:hey
```

### Notes

- Use `host.containers.internal` inside the container to reach services on the host.
- Non-root UID 1001 is used.
- Tools available on PATH: k6, siege, hey.

