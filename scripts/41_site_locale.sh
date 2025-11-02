#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. config/site.env
docker compose -p erpnext-one -f compose/erpnext-one.yaml exec backend \
  bench --site "${ERP_CANON}" set-config default_language es

docker compose -p erpnext-one -f compose/erpnext-one.yaml exec backend \
  bench --site "${ERP_CANON}" set-config time_zone Europe/Madrid