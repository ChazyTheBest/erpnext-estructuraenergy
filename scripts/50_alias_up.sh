#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. config/site.env
cat > env/alias-www-nohyphen.env <<EOV
ROUTER=alias-www-nohyphen
SITES=\`${ERP_ALT_NOHYPHEN}\`
BASE_SITE=${ERP_CANON}
BENCH_NETWORK=erpnext-one
EOV

docker compose --project-name alias-www-nohyphen \
  --env-file env/alias-www-nohyphen.env \
  -f vendor/frappe_docker/overrides/compose.custom-domain.yaml \
  -f vendor/frappe_docker/overrides/compose.custom-domain-ssl.yaml \
  config > compose/alias-www-nohyphen.yaml

docker compose --project-name alias-www-nohyphen -f compose/alias-www-nohyphen.yaml up -d
