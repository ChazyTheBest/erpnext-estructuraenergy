#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. config/site.env
repo_dir="$(pwd)"
sudo mkdir -p /mnt/backups/erpnext
sudo tee /etc/cron.daily/erpnext-backup >/dev/null <<CRON
#!/bin/sh
set -eu
cd "${repo_dir}"
TS="\$(date +%F-%H%M%S)"
docker compose -p erpnext-one -f compose/erpnext-one.yaml exec -T backend \
  bench --site ${ERP_CANON} backup || exit 1
docker compose -p erpnext-one -f compose/erpnext-one.yaml cp \
  backend:/home/frappe/frappe-bench/sites/${ERP_CANON}/private/backups /tmp/bkp-"$TS"
mkdir -p /mnt/backups/erpnext/"$TS"
mv /tmp/bkp-"$TS"/* /mnt/backups/erpnext/"$TS"/
find /mnt/backups/erpnext -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null || true
CRON
sudo chmod +x /etc/cron.daily/erpnext-backup
echo "Installed daily backups to /mnt/backups/erpnext"