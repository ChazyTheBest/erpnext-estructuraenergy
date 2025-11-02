#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. config/site.env

mkdir -p vendor
if [ ! -d vendor/frappe_docker/.git ]; then
  git clone https://github.com/frappe/frappe_docker vendor/frappe_docker
fi

# Freeze upstream to a commit if not yet pinned
if [ -z "${FRAPPE_DOCKER_COMMIT}" ]; then
  FRAPPE_DOCKER_COMMIT="$(git -C vendor/frappe_docker rev-parse HEAD)"
  tmp="$(mktemp)"; awk -v v="$FRAPPE_DOCKER_COMMIT" '
    /^FRAPPE_DOCKER_COMMIT=/{$0="FRAPPE_DOCKER_COMMIT=" v}1' config/site.env >"$tmp"
  mv "$tmp" config/site.env
  echo "Pinned frappe_docker to commit $FRAPPE_DOCKER_COMMIT"
else
  git -C vendor/frappe_docker fetch --all --tags --prune
  git -C vendor/frappe_docker checkout "$FRAPPE_DOCKER_COMMIT"
fi
