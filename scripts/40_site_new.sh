#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. config/site.env
DB_PASS="$(cat secrets/db_password.txt)"
ADMIN_PASS="$(cat secrets/admin_password.txt)"
SITE_PATH="/home/frappe/frappe-bench/sites/${ERP_CANON}"

site_exists() {
  docker compose --project-name erpnext-one exec -T backend \
    test -d "${SITE_PATH}"
}

if site_exists >/dev/null 2>&1; then
  echo "Site ${ERP_CANON} already exists; skipping creation."
else
  docker compose --project-name erpnext-one exec backend \
    bench new-site --mariadb-user-host-login-scope=% \
    --db-root-password "${DB_PASS}" \
    --install-app erpnext \
    --admin-password "${ADMIN_PASS}" \
    "${ERP_CANON}"
fi

if ! site_exists >/dev/null 2>&1; then
  echo "Site ${ERP_CANON} not found; aborting host configuration." >&2
  exit 1
fi

docker compose --project-name erpnext-one exec backend \
  bench --site "${ERP_CANON}" set-config host_name "https://${ERP_CANON}"
