#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
case "${1:-}" in
  erpnext) docker compose -p erpnext-one -f compose/erpnext-one.yaml down ;;
  db)      docker compose -p mariadb --env-file env/mariadb.env -f vendor/frappe_docker/overrides/compose.mariadb-shared.yaml down ;;
  traefik) docker compose -p traefik --env-file env/traefik.env -f vendor/frappe_docker/overrides/compose.traefik.yaml -f vendor/frappe_docker/overrides/compose.traefik-ssl.yaml -f compose/traefik.hsts-redirects.yaml down ;;
  all)
    bash scripts/80_stop.sh erpnext || true
    bash scripts/80_stop.sh db || true
    bash scripts/80_stop.sh traefik || true
    ;;
  *) echo "usage: $0 {erpnext|db|traefik|all}" ; exit 2 ;;
esac
