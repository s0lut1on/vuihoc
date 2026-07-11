#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
# Marketing-site deploy: build, rsync to VPS, purge Cloudflare cache.
#
# Usage:
#   ./scripts/deploy-marketing.sh
#
# Optional env vars:
#   VPS_HOST       (default: deploy@194.233.94.167)
#   VPS_DIR        (default: ~/math-app/math-app)
#   CLOUDFLARE_TOKEN  required for cache purge (otherwise skipped)
#   CLOUDFLARE_ZONE   required for cache purge (otherwise skipped)
#   SKIP_BUILD=1   skip npm run build
#   SKIP_PURGE=1   skip Cloudflare cache purge
# ──────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

VPS_HOST="${VPS_HOST:-deploy@194.233.94.167}"
VPS_DIR="${VPS_DIR:-~/math-app/math-app}"
CLOUDFLARE_TOKEN="${CLOUDFLARE_TOKEN:-}"
CLOUDFLARE_ZONE="${CLOUDFLARE_ZONE:-}"

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; BLUE=$'\033[0;34m'; NC=$'\033[0m'
log()  { echo "${BLUE}[$(date +'%H:%M:%S')]${NC} $*"; }
ok()   { echo "${GREEN}[$(date +'%H:%M:%S')]${NC} $*"; }
warn() { echo "${YELLOW}[$(date +'%H:%M:%S')]${NC} $*"; }
die()  { echo "${RED}[$(date +'%H:%M:%S')] ERROR${NC} $*" >&2; exit 1; }

# ─── 1. Build the site ─────────────────────────────────────────────
if [[ "${SKIP_BUILD:-0}" == "1" ]]; then
  log "Skipping build (SKIP_BUILD=1)"
else
  log "Building marketing site…"
  cd "$APP_DIR/marketing-site"
  npm ci --no-audit --no-fund --loglevel=error
  npm run build
  cd "$APP_DIR"
  ok "Build complete: $(du -sh marketing-site/dist | cut -f1)"
fi

# ─── 2. rsync dist/ to VPS (built static output) ────────────────────
log "Syncing marketing-site/dist/ to ${VPS_HOST}:${VPS_DIR}/marketing-site/dist/ …"
command -v rsync >/dev/null || die "rsync not in PATH (apt install rsync)"

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
  log "Building marketing site…"
  cd "$APP_DIR/marketing-site"
  npm ci --no-audit --no-fund --loglevel=error
  npm run build
  cd "$APP_DIR"
fi

rsync -a --delete \
  --exclude='node_modules' \
  -e "ssh -o ConnectTimeout=10 -o ServerAliveInterval=30" \
  "$APP_DIR/marketing-site/dist/" "${VPS_HOST}:${VPS_DIR}/marketing-site/dist/" \
  || die "rsync failed"
ok "rsync complete"

# ─── 3. Restart marketing-site container (no rebuild needed, bind mount) ──
log "Restarting marketing-site container…"
ssh -o ConnectTimeout=10 "${VPS_HOST}" "cd ${VPS_DIR} && docker compose -f docker-compose.prod.yml restart marketing-site" \
  || die "container restart failed"
ok "Container restarted"

# ─── 4. Purge Cloudflare cache ──────────────────────────────────────
if [[ "${SKIP_PURGE:-0}" == "1" ]]; then
  warn "Skipping Cloudflare purge (SKIP_PURGE=1)"
elif [[ -z "$CLOUDFLARE_TOKEN" || -z "$CLOUDFLARE_ZONE" ]]; then
  warn "Skipping Cloudflare purge (CLOUDFLARE_TOKEN or CLOUDFLARE_ZONE not set)"
  warn "  → Purge manually: Cloudflare dashboard → sekklings.com → Caching → Purge Everything"
else
  log "Purging Cloudflare cache…"
  curl -sS -X POST "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE}/purge_cache" \
    -H "Authorization: Bearer ${CLOUDFLARE_TOKEN}" \
    -H "Content-Type: application/json" \
    --data '{"purge_everything":true}' \
    | python3 -c 'import sys,json; d=json.load(sys.stdin); print("  result:", d.get("success"), d.get("errors", []))' \
    || warn "Cloudflare purge failed — purge manually"
  ok "Cloudflare cache purged"
fi

# ─── 5. Smoke test ──────────────────────────────────────────────────
log "Smoke testing…"
sleep 2
echo
for path in "/" "/lessons" "/lessons/numbers/1" "/brand/og-image-vi.png" "/sitemap-0.xml" "/app/"; do
  size=$(curl -sS -o /dev/null -w '%{size_download}' "https://sekklings.com${path}" 2>/dev/null || echo "ERR")
  status=$(curl -sS -o /dev/null -w '%{http_code}' "https://sekklings.com${path}" 2>/dev/null || echo "ERR")
  printf "  %-32s HTTP %s  %s bytes\n" "$path" "$status" "$size"
done

ok "Deploy complete. Visit https://sekklings.com/ in a hard-refreshed browser."
