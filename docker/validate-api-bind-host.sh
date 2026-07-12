#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
compose_file=${1:-"${repo_root}/docker-compose.yaml"}

assert_api_host() {
  local expected_host=$1
  shift

  "$@" docker compose --file "${compose_file}" --profile host-egress config --format json |
    python3 -c '
import json
import sys

expected_host = sys.argv[1]
services = json.load(sys.stdin)["services"]
effective_internal_port = int(services["api"]["environment"]["PORT"])
ports = services["egress-1"]["ports"]
api_port = next(port for port in ports if port["target"] == effective_internal_port)
actual_host = api_port.get("host_ip")
if actual_host != expected_host:
    raise SystemExit(f"expected API host {expected_host!r}, got {actual_host!r}")
' "${expected_host}"
}

assert_api_host 127.0.0.1 env -u API_BIND_HOST
assert_api_host 127.0.0.1 env API_BIND_HOST=
assert_api_host 127.0.0.1 env API_BIND_HOST=0.0.0.0
assert_api_host 127.0.0.1 env API_BIND_HOST= INTERNAL_PORT=43002

echo "API bind-host compose contract passed"
