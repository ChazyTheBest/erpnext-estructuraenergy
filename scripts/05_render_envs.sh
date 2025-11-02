#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. config/site.env
mkdir -p env secrets

# --- Traefik env with BASIC auth ---
DASH_PW="$(openssl rand -base64 18)"
HASH="$(openssl passwd -apr1 "$DASH_PW")"
cat > env/traefik.env <<EOV
EMAIL=${ACME_EMAIL}
BASIC_USER=admin
HASHED_PASSWORD=${HASH}
EOV
printf "user=admin\npassword=%s\n" "$DASH_PW" > secrets/traefik_basic.txt
chmod 600 secrets/traefik_basic.txt

# --- MariaDB secret ---
DB_PASS="$(openssl rand -base64 24)"
printf "%s\n" "$DB_PASS" > secrets/db_password.txt
chmod 600 secrets/db_password.txt
cat > env/mariadb.env <<EOV
DB_PASSWORD=${DB_PASS}
EOV

# --- ERPNext env ---
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

# --- Admin password for first site ---
ADMIN_PASS="$(openssl rand -base64 20)"
printf "%s\n" "$ADMIN_PASS" > secrets/admin_password.txt
chmod 600 secrets/admin_password.txt

echo "Rendered envs."
echo "  - Traefik BASIC creds saved at secrets/traefik_basic.txt"
echo "  - DB root password saved at secrets/db_password.txt"
echo "  - ERPNext admin password saved at secrets/admin_password.txt"
