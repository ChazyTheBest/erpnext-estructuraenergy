#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. config/site.env
# Ensure bench network exists before starting Traefik
docker network inspect erpnext-one >/dev/null 2>&1 || docker network create erpnext-one

dashboard_mode="${TRAEFIK_DASHBOARD:-off}"
compose_files=()
if [[ "$dashboard_mode" == "on" ]]; then
  compose_files+=(
    -f vendor/frappe_docker/overrides/compose.traefik.yaml
    -f vendor/frappe_docker/overrides/compose.traefik-ssl.yaml
  )
else
  compose_files+=(-f compose/traefik.base.yaml)
fi
compose_files+=(
  -f compose/traefik.hsts-redirects.yaml
  -f compose/traefik.network.yaml
)

docker compose --project-name traefik \
  --env-file env/traefik.env \
  "${compose_files[@]}" up -d
