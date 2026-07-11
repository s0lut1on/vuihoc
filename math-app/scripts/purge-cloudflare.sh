#!/usr/bin/env bash
# Purge Cloudflare cache for sekklings.com
#
# Usage: CLOUDFLARE_TOKEN=xxx CLOUDFLARE_ZONE=yyy ./scripts/purge-cloudflare.sh
#
# Get token: https://dash.cloudflare.com/profile/api-tokens (Edit: zone cache purge)
# Get zone: from the URL of your Cloudflare dashboard for the domain

set -euo pipefail
: "${CLOUDFLARE_TOKEN:?Set CLOUDFLARE_TOKEN env var}"
: "${CLOUDFLARE_ZONE:?Set CLOUDFLARE_ZONE env var}"

DOMAIN="${DOMAIN:-sekklings.com}"
URLS=(
  "https://${DOMAIN}/"
  "https://${DOMAIN}/lessons"
  "https://${DOMAIN}/lessons/"
  "https://${DOMAIN}/brand/og-image-vi.png"
  "https://${DOMAIN}/brand/og-image-en.png"
  "https://${DOMAIN}/brand/favicon.ico"
  "https://${DOMAIN}/sitemap-index.xml"
)

echo "Purging ${#URLS[@]} URLs from Cloudflare…"
curl -sS -X POST "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE}/purge_cache" \
  -H "Authorization: Bearer ${CLOUDFLARE_TOKEN}" \
  -H "Content-Type: application/json" \
  --data "$(python3 -c "import json; print(json.dumps({'files': $(printf '%s\n' "${URLS[@]}" | python3 -c 'import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))')}))")" \
  | python3 -m json.tool

echo
echo "Purged. Hard refresh the browser (Cmd-Shift-R) to see new content."
