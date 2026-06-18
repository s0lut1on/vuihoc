#!/usr/bin/env bash
#
# Manual deploy to VPS — bypasses CI/CD when GHCR/CI is broken.
#
# Usage:
#   ./scripts/deploy.sh                              # full deploy
#   ./scripts/deploy.sh --service auth-service       # single backend service
#   ./scripts/deploy.sh --service user-service --service content-service
#   ./scripts/deploy.sh --skip-frontend              # backend-only (faster)
#   ./scripts/deploy.sh --skip-backend               # frontend-only
#   ./scripts/deploy.sh --no-cache                   # force Docker rebuild from scratch
#   ./scripts/deploy.sh --vps 1.2.3.4                # override host
#   ./scripts/deploy.sh --user deploy                # override SSH user
#
# Required env:
#   GOOGLE_CLIENT_ID   — Google OAuth web client ID for Flutter build
#   VPS_SSH_KEY        — path to private SSH key (default: ~/.ssh/id_rsa)
#
set -euo pipefail

# ─── Config ────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOCAL_FRONTEND="$LOCAL_ROOT/frontend"
LOCAL_BACKEND="$LOCAL_ROOT/backend"

VPS_HOST="${VPS_HOST:-194.233.94.167}"
VPS_USER="${VPS_USER:-deploy}"
VPS_DIR="${VPS_DIR:-~/math-app/math-app}"
SSH_KEY="${VPS_SSH_KEY:-$HOME/.ssh/id_rsa}"
GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID:-}"

SKIP_FRONTEND=false
SKIP_BACKEND=false
NO_CACHE=false
SERVICES=()

# ─── Args ──────────────────────────────────────────────────────────────────
usage() {
  sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-frontend)        SKIP_FRONTEND=true; shift ;;
    --skip-backend)         SKIP_BACKEND=true; shift ;;
    --no-cache)             NO_CACHE=true; shift ;;
    --service)              SERVICES+=("$2"); shift 2 ;;
    --vps)                  VPS_HOST="$2"; shift 2 ;;
    --user)                 VPS_USER="$2"; shift 2 ;;
    --remote-dir)           VPS_DIR="$2"; shift 2 ;;
    --google-client-id)     GOOGLE_CLIENT_ID="$2"; shift 2 ;;
    -h|--help)              usage ;;
    *)                      echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# ─── Helpers ───────────────────────────────────────────────────────────────
RED=$'\033[0;31m'; GRN=$'\033[0;32m'; YEL=$'\033[1;33m'; BLU=$'\033[0;34m'; NC=$'\033[0m'
step() { printf "${BLU}==>${NC} %s\n" "$*"; }
ok()   { printf "${GRN}✅${NC} %s\n" "$*"; }
warn() { printf "${YEL}⚠️${NC}  %s\n" "$*"; }
err()  { printf "${RED}❌${NC} %s\n" "$*" >&2; exit 1; }

SSH_OPTS=(-o ConnectTimeout=10 -o ServerAliveInterval=30)
[[ -f "$SSH_KEY" ]] && SSH_OPTS+=(-i "$SSH_KEY")

ssh_run() { ssh "${SSH_OPTS[@]}" "$VPS_USER@$VPS_HOST" "$@"; }
rsync_to() { rsync -az --delete "$@" "$VPS_USER@$VPS_HOST:"; }

# ─── Pre-flight ───────────────────────────────────────────────────────────
step "Pre-flight checks"
command -v docker >/dev/null || err "docker not on PATH (local)"
command -v flutter >/dev/null || warn "flutter not on PATH — frontend build will skip"
command -v rsync >/dev/null || err "rsync not on PATH"
[[ -n "$GOOGLE_CLIENT_ID" ]] || err "GOOGLE_CLIENT_ID env var required (use --google-client-id)"

ssh_run "docker --version && docker compose version" >/dev/null || err "VPS unreachable or docker compose missing"

# ─── Step 1: Build Flutter web locally ────────────────────────────────────
if ! $SKIP_FRONTEND; then
  if command -v flutter >/dev/null; then
    step "Building Flutter web (local)"
    (cd "$LOCAL_FRONTEND" && \
      flutter build web --release \
        --dart-define=GOOGLE_CLIENT_ID="$GOOGLE_CLIENT_ID" \
        --no-tree-shake-icons) \
      || err "Flutter build failed"
    ok "Flutter web built → build/web/"
  else
    warn "flutter not on PATH; skipping build (using existing build/web/)"
  fi

  step "Syncing build/web to VPS"
  mkdir -p /tmp/flutter-build
  rsync -az --delete "$LOCAL_FRONTEND/build/web/" /tmp/flutter-build/
  ssh_run "rm -rf /tmp/flutter-build" >/dev/null 2>&1 || true
  rsync_to /tmp/flutter-build/ /tmp/flutter-build/

  step "Replacing files in running flutter-web container (GHCR base image is broken)"
  ssh_run "
    set -e
    docker exec math-app-flutter-web-1 sh -c 'rm -rf /usr/share/nginx/html/* /usr/share/nginx/html/.[!.]*' || true
    docker cp /tmp/flutter-build/. math-app-flutter-web-1:/usr/share/nginx/html/

    BUILD_TS=\$(date +%s)
    docker exec math-app-flutter-web-1 sh -c \"
      sed -i 's/\\\"main.dart.js\\\"/\\\"main.dart.js?v=\${BUILD_TS}\\\"/g' /usr/share/nginx/html/flutter_bootstrap.js
      sed -i 's/flutter_bootstrap.js/flutter_bootstrap.js?v=\${BUILD_TS}/g' /usr/share/nginx/html/index.html
    \"
    docker restart math-app-flutter-web-1
  "
  ok "Frontend deployed (cache-busted)"
fi

# ─── Step 2: Sync source to VPS ──────────────────────────────────────────
step "Syncing source to VPS"
rsync_to \
  --exclude='frontend/build/' \
  --exclude='frontend/.dart_tool/' \
  --exclude='frontend/.flutter-plugins' \
  --exclude='frontend/.flutter-plugins-dependencies' \
  --exclude='backend/target/' \
  --exclude='node_modules/' \
  --exclude='.git/' \
  --exclude='e2e/test-results/' \
  --exclude='e2e/playwright-report/' \
  "$LOCAL_ROOT/" "$VPS_DIR/"
ok "Source synced → $VPS_USER@$VPS_HOST:$VPS_DIR"

# ─── Step 3: Rebuild + restart services ───────────────────────────────────
if ! $SKIP_BACKEND; then
  step "Rebuilding backend services"
  BUILD_FLAGS=()
  $NO_CACHE && BUILD_FLAGS+=(--no-cache)
  if [[ ${#SERVICES[@]} -gt 0 ]]; then
    ssh_run "cd $VPS_DIR && docker compose -f docker-compose.prod.yml build ${BUILD_FLAGS[*]} ${SERVICES[*]}" \
      || err "Build failed for: ${SERVICES[*]}"
    UP_TARGETS=("${SERVICES[@]}")
  else
    ssh_run "cd $VPS_DIR && docker compose -f docker-compose.prod.yml build ${BUILD_FLAGS[*]}" \
      || err "Build failed"
    UP_TARGETS=()
  fi
  ok "Built: ${SERVICES[*]:-all}"

  step "Restarting services"
  ssh_run "cd $VPS_DIR && docker compose -f docker-compose.prod.yml up -d ${UP_TARGETS[*]}" \
    || err "Restart failed"
  ok "Services up: ${UP_TARGETS[*]:-all}"
fi

# ─── Step 4: Health check ─────────────────────────────────────────────────
step "Health check (waiting 10s for containers to settle)"
sleep 10
if [[ -x "$LOCAL_ROOT/scripts/health-check.sh" ]]; then
  BASE_URL="${BASE_URL:-https://$(ssh_run 'grep ^DOMAIN= '"$VPS_DIR"'/.env 2>/dev/null | cut -d= -f2 | tr -d "\r" || echo sekklings.com')}" \
    "$LOCAL_ROOT/scripts/health-check.sh" \
    || warn "Some health checks failed (see above) — services may still be starting"
else
  warn "scripts/health-check.sh not found or not executable; skipping"
fi

# ─── Done ─────────────────────────────────────────────────────────────────
DOMAIN="$(ssh_run "grep ^DOMAIN= $VPS_DIR/.env 2>/dev/null | cut -d= -f2 | tr -d '\r'" 2>/dev/null || echo sekklings.com)"
ok "Deploy complete."
ok "  Web:   https://${DOMAIN}/"
ok "  Login: https://${DOMAIN}/login"
