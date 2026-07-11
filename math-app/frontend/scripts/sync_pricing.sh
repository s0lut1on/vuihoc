#!/usr/bin/env bash
# Sync math-app/pricing.json → math-app/frontend/assets/pricing.json.
# Run by: prebuild (Makefile), CI, or manually before flutter build.
# Exits 1 if the validator fails.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROOT_DIR="$(cd "${APP_DIR}/.." && pwd)"
SRC="${ROOT_DIR}/pricing.json"
DST_DIR="${APP_DIR}/assets"
DST="${DST_DIR}/pricing.json"

if [[ ! -f "$SRC" ]]; then
  echo "✗ pricing.json not found at $SRC" >&2
  exit 1
fi

# Validate before copying (fail-loud on schema errors)
python3 "${ROOT_DIR}/scripts/validate_pricing.py"

mkdir -p "$DST_DIR"
cp "$SRC" "$DST"
echo "✓ pricing.json synced to ${DST}"
