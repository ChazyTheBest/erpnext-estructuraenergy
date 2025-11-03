#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose --project-name mariadb \
  --env-file env/mariadb.env \
  -f vendor/frappe_docker/overrides/compose.mariadb-shared.yaml -f compose/mariadb.network.yaml up -d
