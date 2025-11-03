#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

info() {
  printf '==> %s\n' "$*"
}

warn() {
  printf 'WARN: %s\n' "$*" >&2
}

fatal() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: scripts/99_destroy.sh [--force]

Fully tear down the ERPNext deployment, removing containers, networks,
volumes (including lingering compose-managed resources), generated docker-compose
bundle, environment files, secrets, vendored frappe_docker clone, and the backup
cron job plus /mnt/backups/erpnext contents.

Options:
  --force   Skip interactive confirmations (dangerous).
  -h, --help  Show this help message and exit.
EOF
}

force=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --force)
      force=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if [ "$force" -ne 1 ]; then
  if [ ! -t 0 ]; then
    fatal "Interactive confirmations are required. Re-run with --force to bypass prompts."
  fi
  printf 'This will remove all ERPNext-related containers, networks, volumes (including leftovers),\n'
  printf 'generated docker-compose bundle, env files, secrets, vendored frappe_docker clone,\n'
  printf 'and the backup cron job with /mnt/backups/erpnext contents.\n'
  printf 'Continue? [y/N]: '
  read -r reply
  case "${reply,,}" in
    y|yes) ;;
    *)
      printf 'Aborted by user.\n'
      exit 0
      ;;
  esac
  printf 'Type DESTROY to confirm: '
  read -r second
  if [ "${second}" != "DESTROY" ]; then
    printf 'Confirmation token mismatch; aborting.\n'
    exit 0
  fi
fi

docker_bin="$(command -v docker || true)"

destroy_project() {
  local project="$1"
  shift || true
  if [ -z "$docker_bin" ]; then
    warn "docker binary not found; skipping compose teardown for project ${project}"
    return
  fi
  if [ "$#" -gt 0 ]; then
    if ! "$docker_bin" compose --project-name "$project" "$@" down -v --remove-orphans; then
      warn "docker compose down failed for project ${project}; attempting manual cleanup"
    fi
  fi

  local ids
  ids="$("$docker_bin" ps -aq --filter "label=com.docker.compose.project=${project}")"
  if [ -n "$ids" ]; then
    info "Removing remaining containers for ${project}"
    "$docker_bin" rm -fv $ids >/dev/null 2>&1 || warn "failed to remove some containers for ${project}"
  fi

  local nets
  nets="$("$docker_bin" network ls -q --filter "label=com.docker.compose.project=${project}")"
  if [ -n "$nets" ]; then
    info "Removing remaining networks for ${project}"
    "$docker_bin" network rm $nets >/dev/null 2>&1 || warn "failed to remove some networks for ${project}"
  fi

  local vols
  vols="$("$docker_bin" volume ls -q --filter "label=com.docker.compose.project=${project}")"
  if [ -n "$vols" ]; then
    info "Removing remaining volumes for ${project}"
    "$docker_bin" volume rm $vols >/dev/null 2>&1 || warn "failed to remove some volumes for ${project}"
  fi
}

cleanup_network() {
  local network="$1"
  if [ -z "$docker_bin" ]; then
    return
  fi
  if "$docker_bin" network inspect "$network" >/dev/null 2>&1; then
    info "Removing network ${network}"
    "$docker_bin" network rm "$network" >/dev/null 2>&1 || warn "failed to remove network ${network}"
  fi
}

info "Stopping ERPNext stack"
erpnext_config="compose/erpnext-one.yaml"
if [ -f "$erpnext_config" ]; then
  destroy_project "erpnext-one" -f "$erpnext_config"
else
  destroy_project "erpnext-one"
fi

info "Stopping Traefik stack"
traefik_args=()
traefik_missing=0
if [ -f "env/traefik.env" ]; then
  traefik_args+=(--env-file "env/traefik.env")
else
  traefik_missing=1
fi
for file in \
  vendor/frappe_docker/overrides/compose.traefik.yaml \
  vendor/frappe_docker/overrides/compose.traefik-ssl.yaml \
  compose/traefik.hsts-redirects.yaml \
  compose/traefik.network.yaml
do
  if [ -f "$file" ]; then
    traefik_args+=(-f "$file")
  else
    traefik_missing=1
  fi
done
if [ "$traefik_missing" -eq 0 ]; then
  destroy_project "traefik" "${traefik_args[@]}"
else
  destroy_project "traefik"
fi

info "Stopping MariaDB stack"
mariadb_missing=0
mariadb_args=()
if [ -f "env/mariadb.env" ]; then
  mariadb_args+=(--env-file "env/mariadb.env")
else
  mariadb_missing=1
fi
for file in \
  vendor/frappe_docker/overrides/compose.mariadb-shared.yaml \
  compose/mariadb.network.yaml
do
  if [ -f "$file" ]; then
    mariadb_args+=(-f "$file")
  else
    mariadb_missing=1
  fi
done
if [ "$mariadb_missing" -eq 0 ]; then
  destroy_project "mariadb" "${mariadb_args[@]}"
else
  destroy_project "mariadb"
fi

cleanup_network "erpnext-one"
cleanup_network "mariadb-network"
cleanup_network "traefik-public"

info "Removing generated configuration and secrets"
rm -f compose/erpnext-one.yaml
rm -rf env secrets

if [ -d "vendor/frappe_docker" ]; then
  info "Removing vendored frappe_docker clone"
  rm -rf vendor/frappe_docker
fi
if [ -d "vendor" ] && [ -z "$(ls -A vendor)" ]; then
  rmdir vendor 2>/dev/null || true
fi

backup_cleanup=0
if [ "$(id -u)" -eq 0 ]; then
  backup_cleanup=1
elif command -v sudo >/dev/null 2>&1; then
  backup_cleanup=1
else
  warn "sudo not available; skipping removal of installed backup cron job"
fi

if [ "$backup_cleanup" -eq 1 ]; then
  sudo_cmd=()
  if [ "$(id -u)" -ne 0 ]; then
    sudo_cmd=(sudo)
  fi
  for path in /etc/default/erpnext-backup /etc/cron.daily/erpnext-backup; do
    if [ -e "$path" ]; then
      info "Removing ${path}"
      "${sudo_cmd[@]}" rm -f "$path" || warn "failed to remove ${path}"
    fi
  done
  if [ -d "/mnt/backups/erpnext" ]; then
    info "Removing /mnt/backups/erpnext"
    "${sudo_cmd[@]}" rm -rf /mnt/backups/erpnext || warn "failed to remove /mnt/backups/erpnext"
  fi
fi

info "Host cleanup complete."
