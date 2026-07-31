#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV="/tmp/sca-selenium-venv"

if [[ ! -x "${VENV}/bin/python" ]]; then
  echo "Missing virtualenv at ${VENV}" >&2
  exit 1
fi

exec "${VENV}/bin/python" "${ROOT_DIR}/tooling/selenium_smoke_test.py"
