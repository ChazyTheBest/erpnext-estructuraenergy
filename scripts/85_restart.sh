#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

usage() {
  echo "usage: $0 {erpnext|db|traefik|all}" >&2
  exit 2
}

target="${1:-all}"

case "$target" in
  erpnext|db|traefik|all)
    bash scripts/80_stop.sh "$target" || true
    bash scripts/70_start.sh "$target"
    ;;
  *)
    usage
    ;;
esac
