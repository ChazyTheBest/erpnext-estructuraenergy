#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

usage() {
  echo "usage: $0 {erpnext|db|traefik|all}" >&2
  exit 2
}

require_file() {
  local path="$1"
  if [ ! -f "$path" ]; then
    echo "Missing required file: $path" >&2
    return 1
  fi
}

start_traefik() {
  require_file config/site.env
  require_file env/traefik.env
  bash scripts/10_traefik_up.sh
}

start_db() {
  require_file env/mariadb.env
  bash scripts/20_mariadb_up.sh
}

start_erpnext() {
  require_file env/erpnext.env
  if [ ! -d vendor/frappe_docker ]; then
    echo "Missing vendor/frappe_docker; run make init to fetch dependencies." >&2
    return 1
  fi
  bash scripts/30_erpnext_up.sh
}

target="${1:-all}"

case "$target" in
  traefik)
    start_traefik
    ;;
  db)
    start_db
    ;;
  erpnext)
    start_erpnext
    ;;
  all)
    start_traefik
    start_db
    start_erpnext
    ;;
  *)
    usage
    ;;
esac
