#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. config/site.env
mkdir -p env secrets

# Traefik env
cat > env/traefik.env <<EOV
EMAIL=${ACME_EMAIL}
EOV

# MariaDB secret
DB_PASS="$(openssl rand -base64 24)"
printf "%s\n" "$DB_PASS" > secrets/db_password.txt
chmod 600 secrets/db_password.txt
cat > env/mariadb.env <<EOV
DB_PASSWORD=${DB_PASS}
EOV

# ERPNext env
cat > env/erpnext.env <<EOV
ERPNEXT_VERSION=${ERPNEXT_VERSION}
DB_HOST=mariadb-database
DB_PORT=3306
DB_PASSWORD=${DB_PASS}
LETSENCRYPT_EMAIL=${ACME_EMAIL}
SITES=\`${ERP_CANON}\`
ROUTER=erpnext-one
BENCH_NETWORK=erpnext-one
EOV

# Admin password for first site
ADMIN_PASS="$(openssl rand -base64 20)"
printf "%s\n" "$ADMIN_PASS" > secrets/admin_password.txt
chmod 600 secrets/admin_password.txt

echo "Rendered envs. Admin password in secrets/admin_password.txt"
