#!/usr/bin/env bash
# Local deploy script for the math-app stack.
#
# Use when GitHub Actions can't reach the VPS (or the workflow is failing
# silently) and you need to push an update directly.
#
# What this does:
#   1. Validates required env vars are set
#   2. Pulls latest `main` (or whatever ref you set)
#   3. Builds all Docker images locally from source — no GHCR dependency
#   4. Recreates only changed containers (zero-downtime where possible)
#   5. Runs the same health check the GH Actions workflow runs
#
# Usage on VPS:
#   cd ~/math-app/math-app
#   git pull
#   ./scripts/deploy-local.sh
#
# Optional env vars (override defaults):
#   REF=main                    git ref to check out (default: main)
#   APP_VERSION=$(git rev-parse --short HEAD)
#                                APP_VERSION passed to the Flutter build
#                                (default: short HEAD)
#   SKIP_HEALTH_CHECK=1         skip the post-deploy health check
#   SKIP_PULL=1                 don't git pull (you've already done it)
#   SKIP_BUILD=1                skip Docker build (only restart containers)
#   COMPOSE_FILE=docker-compose.prod.yml
#                                which compose to use (default: prod.yml)
#
# Exit codes:
#   0   success
#   1   missing dependency (docker, docker compose)
#   2   git pull failed
#   3   Docker build failed
#   4   Container restart failed
#   5   Health check failed

set -euo pipefail

# ─── Config ─────────────────────────────────────────────
REF="${REF:-main}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.prod.yml}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
APP_VERSION="${APP_VERSION:-$(git rev-parse --short HEAD 2>/dev/null || echo local-dev)}"

# ─── Colors ─────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $*"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING:${NC} $*"; }
err() { echo -e "${RED}[$(date +'%H:%M:%S')] ERROR:${NC} $*" >&2; }
ok() { echo -e "${GREEN}[$(date +'%H:%M:%S')] OK:${NC} $*"; }

# ─── Pre-flight checks ──────────────────────────────────
log "Local deploy script — math-app"
log "REF=$REF APP_VERSION=$APP_VERSION COMPOSE_FILE=$COMPOSE_FILE"
log ""

if [[ "${SKIP_PULL:-0}" != "1" ]]; then
  log "Pre-flight: git pull origin $REF"
  cd "$APP_DIR"
  if ! git pull origin "$REF"; then
    err "git pull failed"
    exit 2
  fi
  ok "git pull complete"
else
  log "Skipping git pull (SKIP_PULL=1)"
fi

# Validate docker
log "Checking Docker..."
if ! command -v docker >/dev/null 2>&1; then
  err "docker not found in PATH"
  exit 1
fi
if ! docker compose version >/dev/null 2>&1; then
  err "'docker compose' (v2) not available"
  exit 1
fi
ok "Docker $(docker --version)"

# Validate compose file exists
COMPOSE_PATH="$APP_DIR/$COMPOSE_FILE"
if [[ ! -f "$COMPOSE_PATH" ]]; then
  err "Compose file not found: $COMPOSE_PATH"
  exit 1
fi

# Validate .env (the deploy compose references ${DOMAIN}, ${AUTH_DB_URL}, etc.)
ENV_PATH="$APP_DIR/.env"
if [[ ! -f "$ENV_PATH" ]]; then
  warn ".env not found at $ENV_PATH — some services may fail to start"
  if [[ -f "$APP_DIR/.env.example" ]]; then
    warn "Hint: copy .env.example to .env and fill in real values"
  fi
fi

# ─── Build images ───────────────────────────────────────
cd "$APP_DIR"
if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
  log ""
  log "Building images locally (this can take a few minutes)..."
  export APP_VERSION

  # --no-cache so we always pick up code changes. Drop if iterating fast.
  if ! docker compose -f "$COMPOSE_FILE" build --no-cache flutter-web; then
    err "flutter-web build failed"
    exit 3
  fi

  # Build the backend services. Matrix here would be nice but keep simple.
  for svc in auth-service user-service content-service progress-service notification-service media-service question-bank-service language-service; do
    if docker compose -f "$COMPOSE_FILE" config --services | grep -qx "$svc"; then
      log "Building $svc..."
      if ! docker compose -f "$COMPOSE_FILE" build --no-cache "$svc"; then
        err "$svc build failed"
        exit 3
      fi
    fi
  done
  ok "All images built"
else
  log "Skipping Docker build (SKIP_BUILD=1)"
fi

# ─── Restart containers ────────────────────────────────
log ""
log "Recreating containers..."
export APP_VERSION

# Pull everything up. --no-deps so unrelated services don't restart.
if ! docker compose -f "$COMPOSE_FILE" up -d --no-deps --force-recreate; then
  err "docker compose up failed"
  exit 4
fi
ok "Containers recreated"

# ─── Health check ───────────────────────────────────────
if [[ "${SKIP_HEALTH_CHECK:-0}" != "1" ]]; then
  log ""
  log "Running health check (waiting 15s for services to settle)..."
  sleep 15

  HEALTH_SCRIPT="$APP_DIR/scripts/health-check.sh"
  if [[ -x "$HEALTH_SCRIPT" ]]; then
    if "$HEALTH_SCRIPT"; then
      ok "Health check passed"
    else
      err "Health check failed"
      warn "Inspect logs with: docker compose -f $COMPOSE_FILE logs --tail=200 <service>"
      exit 5
    fi
  else
    warn "scripts/health-check.sh not found or not executable — skipping"
    warn "Manual check: curl -sI https://\${DOMAIN}/main.dart.js"
  fi
else
  log "Skipping health check (SKIP_HEALTH_CHECK=1)"
fi

log ""
ok "Deploy complete"
ok "  APP_VERSION: $APP_VERSION"
ok "  Verify: open https://<your-domain> and check the home-screen footer"
ok "          should read: 🐸 HocVui $APP_VERSION"
