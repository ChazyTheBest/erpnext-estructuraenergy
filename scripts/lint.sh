#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "shellcheck not found on PATH; install it to run script linting." >&2
  exit 127
fi

shellcheck -x scripts/*.sh
