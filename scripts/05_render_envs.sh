#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. config/site.env
mkdir -p env secrets

DASH_PW="$(openssl rand -base64 18)"
HASH="$(openssl passwd -apr1 "$DASH_PW" | sed 's/\$/$$/g')"

cat > env/traefik.env <<EOV
EMAIL=${ACME_EMAIL}
BASIC_USER=admin
HASHED_PASSWORD=${HASH}
TRAEFIK_DOMAIN=traefik.${ERP_APEX}
DASHBOARD=${TRAEFIK_DASHBOARD:-off}
EOV
printf "user=admin\npassword=%s\n" "$DASH_PW" > secrets/traefik_basic.txt
chmod 600 secrets/traefik_basic.txt

DB_PASS="$(openssl rand -base64 24)"
printf "%s\n" "$DB_PASS" > secrets/db_password.txt
chmod 600 secrets/db_password.txt
cat > env/mariadb.env <<EOV
DB_PASSWORD=${DB_PASS}
EOV

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

ADMIN_PASS="$(openssl rand -base64 20)"
printf "%s\n" "$ADMIN_PASS" > secrets/admin_password.txt
chmod 600 secrets/admin_password.txt

echo "Rendered envs."
