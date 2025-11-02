#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. config/site.env

# Ensure shared network exists before starting Traefik
docker network inspect "${ERP_CANON%.*}" >/dev/null 2>&1 || true
docker network inspect erpnext-one >/dev/null 2>&1 || docker network create erpnext-one

docker compose --project-name traefik \
  --env-file env/traefik.env \
  -f vendor/frappe_docker/overrides/compose.traefik.yaml \
  -f vendor/frappe_docker/overrides/compose.traefik-ssl.yaml \
  -f compose/traefik.hsts-redirects.yaml \
  -f compose/traefik.network.yaml up -d