#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
docker network inspect erpnext-one >/dev/null 2>&1 || docker network create erpnext-one
docker compose --project-name mariadb \
  --env-file env/mariadb.env \
  -f vendor/frappe_docker/overrides/compose.mariadb-shared.yaml -f compose/mariadb.network.yaml up -d
