#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. config/site.env
DB_PASS="$(cat secrets/db_password.txt)"
ADMIN_PASS="$(cat secrets/admin_password.txt)"
docker compose --project-name erpnext-one exec backend \
  bench new-site --mariadb-user-host-login-scope=% \
  --db-root-password "${DB_PASS}" \
  --install-app erpnext \
  --admin-password "${ADMIN_PASS}" \
  "${ERP_CANON}"

docker compose --project-name erpnext-one exec backend \
  bench --site "${ERP_CANON}" set-config host_name "https://${ERP_CANON}"
