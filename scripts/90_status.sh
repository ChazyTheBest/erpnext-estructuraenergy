#!/usr/bin/env bash
set -euo pipefail
docker compose ls
echo
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
