#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose --project-name erpnext-one \
  --env-file env/erpnext.env \
  -f vendor/frappe_docker/compose.yaml \
  -f vendor/frappe_docker/overrides/compose.redis.yaml \
  -f vendor/frappe_docker/overrides/compose.multi-bench.yaml \
  -f vendor/frappe_docker/overrides/compose.multi-bench-ssl.yaml \
  config > compose/erpnext-one.yaml

docker compose --project-name erpnext-one -f compose/erpnext-one.yaml up -d
