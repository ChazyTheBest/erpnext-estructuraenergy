#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

compose_down_if_ready() {
  local project="$1"
  shift || true
  local missing=0
  local args=()
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --env-file|-f)
        local flag="$1"
        local value="${2:-}"
        if [ -z "$value" ] || [ ! -f "$value" ]; then
          missing=1
        else
          args+=("$flag" "$value")
        fi
        shift 2
        ;;
      *)
        args+=("$1")
        shift
        ;;
    esac
  done
  if [ "$missing" -eq 1 ]; then
    echo "Required compose inputs missing for project ${project}; skipping stop." >&2
    return 0
  fi
  docker compose -p "$project" "${args[@]}" down
}

case "${1:-}" in
  erpnext)
    compose_down_if_ready erpnext-one -f compose/erpnext-one.yaml
    ;;
  db)
    compose_down_if_ready mariadb \
      --env-file env/mariadb.env \
      -f vendor/frappe_docker/overrides/compose.mariadb-shared.yaml \
      -f compose/mariadb.network.yaml
    ;;
  traefik)
    compose_down_if_ready traefik \
      --env-file env/traefik.env \
      -f vendor/frappe_docker/overrides/compose.traefik.yaml \
      -f vendor/frappe_docker/overrides/compose.traefik-ssl.yaml \
      -f compose/traefik.hsts-redirects.yaml \
      -f compose/traefik.network.yaml
    ;;
  all)
    bash scripts/80_stop.sh erpnext || true
    bash scripts/80_stop.sh db || true
    bash scripts/80_stop.sh traefik || true
    ;;
  *) echo "usage: $0 {erpnext|db|traefik|all}" ; exit 2 ;;
esac
