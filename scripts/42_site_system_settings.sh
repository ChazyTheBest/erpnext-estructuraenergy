#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. config/site.env
docker compose -p erpnext-one -f compose/erpnext-one.yaml exec -T backend \
  bench --site "${ERP_CANON}" execute frappe.core.doctype.system_settings.system_settings.update_system_settings \
  --args '{"language":"es","time_zone":"Europe/Madrid"}'
