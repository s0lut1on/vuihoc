#!/usr/bin/env bash
# One-shot VPS deploy — paste into your terminal from your laptop.
#
# This is a self-contained shell snippet that does everything needed to
# push the current `main` to a running VPS without needing GitHub
# Actions to fire. Pastes cleanly into any modern terminal.
#
# Pre-reqs (one-time):
#   - You have SSH access to the VPS: `ssh USER@HOST`
#   - Your SSH key is loaded (ssh-add ~/.ssh/id_ed25519_vps)
#   - The VPS already has the repo at ~/math-app/math-app (clone once with
#     `git clone git@github.com:s0lut1on/vuihoc.git ~/math-app`)
#
# Edit the two variables below before running.

VPS_HOST="${VPS_HOST:-s0lut1on@sekklings.com}"
VPS_DIR="${VPS_DIR:-/root/math-app/math-app}"

set -euo pipefail

# ─── Pre-flight on laptop ──────────────────────────────
if ! command -v ssh >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1; then
  echo "❌ ssh and git are required"
  exit 1
fi

# Make sure the local repo is on the latest main.
echo "🔍 Checking local git state..."
LOCAL_SHA=$(git rev-parse --short HEAD)
LOCAL_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "  Local: $LOCAL_BRANCH @ $LOCAL_SHA"

if [[ "$LOCAL_BRANCH" != "main" ]]; then
  echo "⚠️  Not on main. Switching..."
  git checkout main
  git pull origin main
  LOCAL_SHA=$(git rev-parse --short HEAD)
fi

# Test SSH connection (fail fast before we waste time)
echo "🔌 Testing SSH to $VPS_HOST..."
if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "$VPS_HOST" true 2>/dev/null; then
  echo "❌ Cannot SSH to $VPS_HOST — check keys and network"
  exit 1
fi
echo "  ✓ SSH works"

# ─── Push to origin (so VPS git pull gets the same SHA) ─
echo "📤 Ensuring $LOCAL_SHA is on origin/main..."
git push origin "$LOCAL_SHA:refs/heads/main" 2>/dev/null \
  || echo "  (push skipped — likely already there)"

# ─── Run deploy on VPS ────────────────────────────────
echo ""
echo "🚀 Running deploy on $VPS_HOST ..."
echo ""

ssh "$VPS_HOST" "VPS_DIR='$VPS_DIR' bash -s" <<REMOTE
set -euo pipefail

# Resolve ~ in VPS_DIR
VPS_DIR="\${VPS_DIR/#\~/\$HOME}"
cd "\$VPS_DIR"

echo "  📂 Working dir: \$VPS_DIR"
echo "  📌 HEAD: \$(git rev-parse --short HEAD)"

echo ""
echo "  🔄 git pull origin main"
git pull origin main

echo ""
echo "  🐳 Checking Docker..."
command -v docker >/dev/null 2>&1 || { echo "  ❌ docker not found"; exit 1; }
docker compose version >/dev/null 2>&1 || { echo "  ❌ docker compose v2 not found"; exit 1; }

echo ""
echo "  🛠  Building flutter-web + backend services (no-cache)..."
APP_VERSION="\$(git rev-parse --short HEAD)"
export APP_VERSION
docker compose -f docker-compose.prod.yml build --no-cache flutter-web
for svc in auth-service user-service content-service progress-service notification-service media-service question-bank-service language-service; do
  if docker compose -f docker-compose.prod.yml config --services 2>/dev/null | grep -qx "\$svc"; then
    echo "    • building \$svc"
    docker compose -f docker-compose.prod.yml build --no-cache "\$svc"
  fi
done

echo ""
echo "  🔁 Recreating containers..."
docker compose -f docker-compose.prod.yml up -d --no-deps --force-recreate

echo ""
echo "  ⏳ Waiting 15s for services to settle..."
sleep 15

echo ""
echo "  🩺 Health check..."
if [[ -x ./scripts/health-check.sh ]]; then
  if ./scripts/health-check.sh; then
    echo "  ✅ Health check passed"
  else
    echo "  ⚠️  Health check reported problems — inspect logs"
    echo "  docker compose -f docker-compose.prod.yml logs --tail=200 <service>"
  fi
else
  echo "  ⚠️  scripts/health-check.sh not present, skipping"
fi

echo ""
echo "  ✅ Deploy complete"
echo "  APP_VERSION=\$APP_VERSION"
echo "  Verify: open the app and check the home-screen footer"
echo "          (should read: 🐸 HocVui \$APP_VERSION)"
REMOTE

echo ""
echo "✅ VPS deploy complete!"
echo "   Local SHA pushed:    $LOCAL_SHA"
echo "   VPS head:            see output above"
echo "   Verify:              https://sekklings.com → Home screen footer"
