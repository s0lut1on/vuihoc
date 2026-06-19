#!/usr/bin/env bash
# After GitHub SSH auth is confirmed, run the rest of the bootstrap.
# This script is safe to run on a VPS that already has things in /root.

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $*"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARN${NC} $*"; }
ok()   { echo -e "${GREEN}[$(date +'%H:%M:%S')] OK${NC} $*"; }

VPS_HOST="${VPS_HOST:-root@194.233.94.167}"
INSTALL_DIR="${INSTALL_DIR:-/root/math-app/math-app}"

echo ""
log "Step 1: confirm GitHub auth works from VPS..."
ssh -o BatchMode=yes "$VPS_HOST" "ssh -o BatchMode=yes -T git@github.com"
ok "  -> GitHub reachable from VPS"

log "Step 2: clone repo (or pull if already exists)..."
ssh "$VPS_HOST" <<REMOTE
set -e
if [[ -d "$INSTALL_DIR/.git" ]]; then
  echo "  -> Repo exists, pulling latest..."
  cd "$INSTALL_DIR"
  git fetch origin
  git checkout main
  git pull --rebase origin main
else
  echo "  -> Cloning fresh..."
  mkdir -p "\$(dirname "$INSTALL_DIR")"
  git clone git@github.com:s0lut1on/vuihoc.git "$INSTALL_DIR"
  cd "$INSTALL_DIR"
  git checkout main
fi
echo "  -> HEAD: \$(git rev-parse --short HEAD)"
REMOTE

log "Step 3: install Docker + compose if missing..."
ssh "$VPS_HOST" "command -v docker >/dev/null 2>&1 && command -v docker-compose-plugin >/dev/null 2>&1 && echo '  -> already installed' || (DEBIAN_FRONTEND=noninteractive apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin ca-certificates curl git openssh-server ufw)"
ok "  -> done"

log "Step 4: copy .env.example to .env if missing..."
ssh "$VPS_HOST" "cd $INSTALL_DIR && [[ -f .env ]] && echo '  -> .env exists' || cp .env.example .env && chmod 600 .env && echo '  -> .env created from .env.example (EDIT IT for real passwords + DOMAIN!)'"
warn "  -> ⚠️  You MUST edit .env before deploying (set DOMAIN, passwords)"

log "Step 5: enable ufw (firewall) — only if you already have port 22 allowed..."
ssh "$VPS_HOST" "ufw status | head -1 | grep -q active && echo '  -> ufw already active' || (ufw default allow outgoing && ufw allow 22/tcp && ufw allow 80/tcp && ufw allow 443/tcp && yes | ufw enable)"

log "Step 6: run deploy-local.sh (builds + starts everything)..."
warn "  -> This will take 5-10 minutes for the first build. Watch for errors."
ssh "$VPS_HOST" "cd $INSTALL_DIR && bash scripts/deploy-local.sh"

ok "Done! Open https://<your-domain> in a browser."
echo ""
echo "Next manual steps:"
echo "  1. Edit .env: ssh $VPS_HOST \"nano $INSTALL_DIR/.env\""
echo "  2. Verify build: open https://<your-domain> — check home-screen footer"
echo "  3. Should read: 🐸 HocVui \$(ssh $VPS_HOST 'cd $INSTALL_DIR && git rev-parse --short HEAD')"
echo "  4. Health check: ssh $VPS_HOST \"$INSTALL_DIR/scripts/health-check.sh\""
