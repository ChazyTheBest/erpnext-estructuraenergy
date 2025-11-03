#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. config/site.env
# Ensure bench network exists before starting Traefik
docker network inspect erpnext-one >/dev/null 2>&1 || docker network create erpnext-one

dashboard_mode="${TRAEFIK_DASHBOARD:-off}"
compose_overlays=(
  "-f vendor/frappe_docker/overrides/compose.traefik.yaml"
  "-f vendor/frappe_docker/overrides/compose.traefik-ssl.yaml"
  "-f compose/traefik.hsts-redirects.yaml"
  "-f compose/traefik.network.yaml"
)
if [[ "$dashboard_mode" != "on" ]]; then
  compose_overlays+=("-f compose/traefik.dashboard-off.yaml")
fi

docker compose --project-name traefik \
  --env-file env/traefik.env \
  "${compose_overlays[@]}" up -d
