#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. config/site.env
docker compose --project-name traefik \
  --env-file env/traefik.env \
  -f vendor/frappe_docker/overrides/compose.traefik.yaml \
  -f vendor/frappe_docker/overrides/compose.traefik-ssl.yaml \
  -f compose/traefik.hsts-redirects.yaml up -d
