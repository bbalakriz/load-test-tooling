#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'EOF'
Load-test toolbox container

Available tools:
  - k6         (use with mounted scripts, e.g., k6 run /work/loadtest.js)
  - hey        (preinstalled)

Convenience wrappers:
  - run:hey-caching     -> runs hey-tester-redis-caching.sh
  - run:k6              -> runs k6 with loadtest.js

Bind-mount your project root to /work (payloads should be under /work/payloads).
Examples:
  podman run --rm -it -v "$PWD:/work" IMAGE run:hey-caching
  podman run --rm -it -v "$PWD:/work" IMAGE k6 run /work/loadtest.js
EOF
}

export PATH="/usr/local/bin:$PATH"
cd /work || true

cmd=${1:-help}
shift || true

case "$cmd" in
  # run:siege)
  #   exec bash /work/siege-tester.sh "$@" ;;
  # run:siege-urls)
  #   exec bash /work/siege-tester-urls-per-token.sh "$@" ;;
  # run:hey)
  #   exec bash /work/hey-tester.sh "$@" ;;
  run:hey-caching)
    exec bash /work/hey-tester-redis-caching.sh "$@" ;;
  run:k6)
    exec k6 run /work/loadtest.js "$@" ;;
    
  help|--help|-h)
    show_help ;;
  *)
    if command -v "$cmd" >/dev/null 2>&1; then
      exec "$cmd" "$@"
    else
      echo "Unknown command: $cmd" >&2
      show_help
      exit 1
    fi
    ;;
esac


