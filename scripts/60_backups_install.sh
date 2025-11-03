#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. config/site.env
repo_dir="$(pwd)"
docker_bin="$(command -v docker || true)"
if [ -z "$docker_bin" ]; then
  echo "docker executable not found in PATH; export DOCKER first or install Docker." >&2
  exit 1
fi
repo_line="$(printf 'REPO_DIR=%q' "$repo_dir")"
docker_line="$(printf 'DOCKER_BIN=%q' "$docker_bin")"
sudo mkdir -p /mnt/backups/erpnext
sudo tee /etc/default/erpnext-backup >/dev/null <<CONFIG
$repo_line
$docker_line
CONFIG
sudo chmod 600 /etc/default/erpnext-backup
sudo tee /etc/cron.daily/erpnext-backup >/dev/null <<'CRON'
#!/bin/sh
set -eu
CONFIG_FILE="/etc/default/erpnext-backup"
if [ -f "\$CONFIG_FILE" ]; then
  . "\$CONFIG_FILE"
fi
: "\${REPO_DIR:?REPO_DIR not configured in \$CONFIG_FILE}"
: "\${DOCKER_BIN:?DOCKER_BIN not configured in \$CONFIG_FILE}"
if [ ! -d "\$REPO_DIR" ]; then
  echo "ERPNext backup: repository directory \$REPO_DIR not found" >&2
  exit 1
fi
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
cd "\$REPO_DIR"
if [ ! -f config/site.env ]; then
  echo "ERPNext backup: config/site.env not found under \$REPO_DIR" >&2
  exit 1
fi
set -a
. config/site.env
set +a
TS="\$(date +%F-%H%M%S)"
tmp_dir="\$(mktemp -d "/tmp/bkp-\$TS.XXXXXX")"
cleanup() {
  rm -rf "\$tmp_dir"
}
trap cleanup EXIT
"\$DOCKER_BIN" compose -p erpnext-one -f compose/erpnext-one.yaml exec -T backend \
  bench --site "\$ERP_CANON" backup || exit 1
"\$DOCKER_BIN" compose -p erpnext-one -f compose/erpnext-one.yaml cp \
  "backend:/home/frappe/frappe-bench/sites/\$ERP_CANON/private/backups/." "\$tmp_dir/"
mkdir -p /mnt/backups/erpnext/"\$TS"
cp -a "\$tmp_dir"/. /mnt/backups/erpnext/"\$TS"/
find /mnt/backups/erpnext -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null || true
CRON
sudo chmod +x /etc/cron.daily/erpnext-backup
echo "Installed daily backups to /mnt/backups/erpnext"

