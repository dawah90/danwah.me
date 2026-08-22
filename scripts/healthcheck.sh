#!/usr/bin/env bash
set -euo pipefail

environment="${1:-}"

case "$environment" in
    dev) port=8101 ;;
    test) port=8102 ;;
    prod) port=8103 ;;
    *)
        printf 'Environment must be dev, test or prod.\n' >&2
        exit 2
        ;;
esac

base_url="${DANWAH_BASE_URL:-http://192.168.50.21:$port}"
response=$(curl --fail --silent --show-error --max-time 10 "$base_url/version")

python3 - "$environment" "$response" <<'PY'
import json
import sys

expected_environment = sys.argv[1]
payload = json.loads(sys.argv[2])
actual_environment = payload.get("environment")
if actual_environment != expected_environment:
    raise SystemExit(
        f"Expected environment {expected_environment!r}, got {actual_environment!r}"
    )
print(json.dumps(payload, sort_keys=True))
PY
