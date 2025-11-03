#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. config/site.env
mkdir -p env secrets

hash_password() {
  local password="$1"
  local hashed
  if command -v htpasswd >/dev/null 2>&1; then
    hashed="$(printf '%s\n' "$password" | htpasswd -inBC 12 admin 2>/dev/null | cut -d: -f2)"
  else
    hashed="$(openssl passwd -6 "$password")"
  fi
  hashed="${hashed//$/$$}"
  printf '%s' "$hashed"
}

traefik_password=""
traefik_secret_created=0
if [ -f secrets/traefik_basic.txt ]; then
  traefik_password="$(awk -F= '/^password=/{print $2; exit}' secrets/traefik_basic.txt | tr -d '\r')"
fi
if [ -z "$traefik_password" ]; then
  traefik_password="$(openssl rand -base64 18)"
  traefik_secret_created=1
fi

traefik_hash=""
if [ -f env/traefik.env ]; then
  traefik_hash="$(awk -F= '/^HASHED_PASSWORD=/{print $2; exit}' env/traefik.env | tr -d '\r')"
fi
if [ -z "$traefik_hash" ] || [ "$traefik_secret_created" -eq 1 ]; then
  traefik_hash="$(hash_password "$traefik_password")"
fi

cat > secrets/traefik_basic.txt <<EOF
user=admin
password=${traefik_password}
EOF
chmod 600 secrets/traefik_basic.txt

cat > env/traefik.env <<EOF
EMAIL=${ACME_EMAIL}
BASIC_USER=admin
HASHED_PASSWORD=${traefik_hash}
TRAEFIK_DOMAIN=traefik.${ERP_APEX}
DASHBOARD=${TRAEFIK_DASHBOARD:-off}
EOF

db_pass=""
if [ -f secrets/db_password.txt ]; then
  db_pass="$(tr -d '\r' < secrets/db_password.txt)"
fi
if [ -z "$db_pass" ]; then
  db_pass="$(openssl rand -base64 24)"
fi
printf "%s\n" "$db_pass" > secrets/db_password.txt
chmod 600 secrets/db_password.txt

cat > env/mariadb.env <<EOF
DB_PASSWORD=${db_pass}
EOF

cat > env/erpnext.env <<EOF
ERPNEXT_VERSION=${ERPNEXT_VERSION}
DB_HOST=mariadb-database
DB_PORT=3306
DB_PASSWORD=${db_pass}
LETSENCRYPT_EMAIL=${ACME_EMAIL}
SITES=\`${ERP_CANON}\`
ROUTER=erpnext-one
BENCH_NETWORK=erpnext-one
EOF

admin_pass=""
if [ -f secrets/admin_password.txt ]; then
  admin_pass="$(tr -d '\r' < secrets/admin_password.txt)"
fi
if [ -z "$admin_pass" ]; then
  admin_pass="$(openssl rand -base64 20)"
fi
printf "%s\n" "$admin_pass" > secrets/admin_password.txt
chmod 600 secrets/admin_password.txt

echo "Rendered envs (idempotent)."
