#!/usr/bin/env bash
# After GitHub SSH auth is confirmed, run the rest of the bootstrap.
# Each step is its own SSH call so failures are visible and recoverable.
# Run from your laptop: VPS_HOST=root@... bash post-auth.sh

set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $*"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARN${NC} $*"; }
err()  { echo -e "${RED}[$(date +'%H:%M:%S')] ERR${NC} $*" >&2; }
ok()   { echo -e "${GREEN}[$(date +'%H:%M:%S')] OK${NC} $*"; }

VPS_HOST="${VPS_HOST:-root@194.233.94.167}"
INSTALL_DIR="${INSTALL_DIR:-/root/math-app/math-app}"

step() { echo ""; log "=========== $* ==========="; }

# Step 1: Confirm GitHub auth
step "Step 1/6: confirm GitHub auth works from VPS"
log "ssh -T git@github.com from VPS..."
# The VPS may have multiple keys; ssh picks by name order. Force
# id_rsa (which we just verified works) so this step doesn't fail
# on a wrong key. Also write ~/.ssh/config so git-clone in step 2
# and the deploy in step 6 always use id_rsa without us repeating
# the -i flag everywhere.
ssh "$VPS_HOST" "bash -c '
set -e
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cat > ~/.ssh/config <<CFG
Host github.com
  IdentityFile ~/.ssh/id_rsa
  IdentitiesOnly yes
  StrictHostKeyChecking accept-new
  UserKnownHostsFile ~/.ssh/known_hosts
CFG
chmod 600 ~/.ssh/config
[[ -f ~/.ssh/id_rsa ]] || { echo MISSING_ID_RSA_ON_VPS; exit 1; }
chmod 600 ~/.ssh/id_rsa
ssh-keyscan -t rsa,ed25519 github.com >> ~/.ssh/known_hosts 2>/dev/null || true
sort -u ~/.ssh/known_hosts -o ~/.ssh/known_hosts
chmod 644 ~/.ssh/known_hosts
echo CONFIG_INSTALLED
'"

# Verify by running ssh -T FROM THE VPS. No -i needed because we
# already wrote /root/.ssh/config above (Host github.com /
# IdentityFile ~/.ssh/id_rsa / IdentitiesOnly yes).
# NOTE: GitHub returns exit=1 with 'no shell access' even on SUCCESS.
# So we can't use exit code — check the output string instead.
out=$(ssh "$VPS_HOST" "ssh -o BatchMode=yes -T git@github.com" 2>&1 || true)
echo "$out"
if ! echo "$out" | grep -q "successfully authenticated"; then
  err "GitHub auth did not succeed from VPS. Output was:"
  err "$out"
  err "Most likely: the id_rsa on VPS doesn't match the pubkey on GitHub."
  err "Fix: check https://github.com/settings/keys has the matching pubkey."
  exit 1
fi
ok "GitHub reachable"

# Step 2: Clone or pull
step "Step 2/6: clone repo (or pull if already exists)"
ssh -o ConnectTimeout=30 "$VPS_HOST" "bash -s -- $INSTALL_DIR" <<'REMOTE_EOF'
set -e
if [[ -d "$1/.git" ]]; then
  echo "Repo exists at $1 — pulling latest..."
  cd "$1"
  git fetch origin 2>&1 | tail -3
  git checkout main 2>&1 | tail -2
  git pull --rebase origin main 2>&1 | tail -5
  echo "Now at: $(git rev-parse --short HEAD)"
else
  echo "Cloning fresh into $1..."
  mkdir -p "$(dirname "$1")"
  git clone git@github.com:s0lut1on/vuihoc.git "$1" 2>&1 | tail -5
  cd "$1"
  git checkout main 2>&1 | tail -2
  echo "Now at: $(git rev-parse --short HEAD)"
fi
REMOTE_EOF

# Step 3: Install Docker + Compose if missing
step "Step 3/6: install Docker + Compose v2 if missing"
log "check docker..."
DOCKER_STATE=$(ssh -o ConnectTimeout=10 "$VPS_HOST" "command -v docker >/dev/null 2>&1 && command -v 'docker compose' >/dev/null 2>&1 && echo OK || echo MISSING")
if [[ "$DOCKER_STATE" == "OK" ]]; then
  ok "Docker + Compose v2 already installed"
else
  warn "Installing Docker + Compose v2..."
  ssh "$VPS_HOST" "bash -s" <<'REMOTE_EOF'
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y --no-install-recommends ca-certificates curl gnupg lsb-release
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
docker --version
docker compose version
REMOTE_EOF
  ok "Docker installed"
fi

# Step 4: Create .env from .env.example
step "Step 4/6: copy .env.example to .env if missing"
ENV_STATE=$(ssh "$VPS_HOST" "bash -s -- $INSTALL_DIR" <<'REMOTE_EOF'
set -e
cd "$1"
if [[ -f .env ]]; then
  echo EXISTS
else
  cp .env.example .env
  chmod 600 .env
  echo CREATED
fi
REMOTE_EOF
)
if [[ "$ENV_STATE" == *"EXISTS"* ]]; then
  ok ".env already exists — leaving alone"
else
  warn ".env was CREATED from .env.example. EDIT IT before final deploy:"
  warn "  ssh $VPS_HOST 'nano $INSTALL_DIR/.env'"
  warn "Set at minimum: DOMAIN, LETSENCRYPT_EMAIL, GOOGLE_CLIENT_ID"
fi

# Step 5: Enable ufw safely
step "Step 5/6: enable ufw (with port 22/80/443 allowed)"
ssh "$VPS_HOST" "bash -s" <<'REMOTE_EOF'
set +e
ufw --force reset 2>/dev/null
ufw default allow outgoing 2>/dev/null
ufw allow 22/tcp 2>/dev/null
ufw allow 80/tcp 2>/dev/null
ufw allow 443/tcp 2>/dev/null
yes | ufw enable 2>/dev/null
echo "ufw status:"
ufw status 2>/dev/null
REMOTE_EOF
ok "ufw configured (port 22/80/443 allowed)"

# Step 6: Run deploy-local.sh (the long one)
step "Step 6/6: run deploy-local.sh (5-10 min for first build)"
warn "Watch for errors. The build takes a while."
APP_VERSION=$(ssh "$VPS_HOST" "cd $INSTALL_DIR && git rev-parse --short HEAD")
log "Building with APP_VERSION=$APP_VERSION"
ssh "$VPS_HOST" "bash -s -- $INSTALL_DIR $APP_VERSION" <<'REMOTE_EOF'
set -e
cd "$1"
export APP_VERSION="$2"
bash scripts/deploy-local.sh
echo ""
echo "Deploy complete. APP_VERSION=$APP_VERSION"
REMOTE_EOF

echo ""
ok "DONE! Next steps:"
ok "  1. Edit .env on VPS if you haven't:"
ok "       ssh $VPS_HOST 'nano $INSTALL_DIR/.env'"
ok "  2. Restart with new env (no rebuild):"
ok "       ssh $VPS_HOST 'cd $INSTALL_DIR && bash scripts/deploy-local.sh SKIP_BUILD=1'"
ok "  3. Verify:"
ok "       curl -sI https://sekklings.com | head -3"
ok "       open https://sekklings.com — check home-screen footer"
ok "       Should read: 🐸 HocVui <git-sha>"
