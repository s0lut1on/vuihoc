#!/usr/bin/env bash
# One-shot: push a fresh deploy key to a new VPS so the bootstrap
# can git-clone the private repo. Run this FROM YOUR LAPTOP.
#
# What it does:
#   1. Asks which VPS you're targeting (or uses $VPS_HOST env)
#   2. Generates ~/.ssh/math_app_deploy if missing (laptop side)
#   3. Shows the pubkey so you can add it to GitHub
#   4. Pushes the private key to the VPS via scp
#   5. Locks down perms
#   6. Runs ssh -T git@github.com on the VPS — confirms auth works
#
# Usage (run from your laptop, where you generated/hold the key):
#   VPS_HOST=root@sekklings.com bash math-app/scripts/setup-deploy-key.sh
#   # or, if you don't have the key yet, just run it — it'll generate one
#
# After this:
#   - bash scripts/vps-bootstrap.sh on the VPS will succeed

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $*"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARN${NC} $*"; }
err()  { echo -e "${RED}[$(date +'%H:%M:%S')] ERR${NC} $*" >&2; }
ok()   { echo -e "${GREEN}[$(date +'%H:%M:%S')] OK${NC} $*"; }

# ─── Args ────────────────────────────────────────────────
VPS_HOST="${VPS_HOST:-root@sekklings.com}"
KEY_PATH="${KEY_PATH:-${HOME}/.ssh/math_app_deploy}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--host) VPS_HOST="$2"; shift 2 ;;
    -k|--key)  KEY_PATH="$2"; shift 2 ;;
    --help)
      echo "Usage: $0 [-h user@host] [-k /path/to/key]"
      echo "Env: VPS_HOST (default root@sekklings.com), KEY_PATH (default ~/.ssh/math_app_deploy)"
      exit 0 ;;
    *) err "Unknown arg: $1"; exit 1 ;;
  esac
done

# ─── Pre-flight on laptop ──────────────────────────────
command -v ssh >/dev/null || { err "ssh not found"; exit 1; }
command -v scp >/dev/null || { err "scp not found"; exit 1; }
command -v ssh-keygen >/dev/null || { err "ssh-keygen not found"; exit 1; }

# ─── Step 1: Generate key (if missing) ─────────────────
log "Step 1: ensure deploy key exists at $KEY_PATH..."
if [[ ! -f "$KEY_PATH" ]]; then
  log "  -> generating new ed25519 key"
  mkdir -p "$(dirname "$KEY_PATH")"
  chmod 700 "$(dirname "$KEY_PATH")"
  ssh-keygen -t ed25519 -f "$KEY_PATH" -C "vps-deploy-$(date +%Y%m%d)" -N ""
  ok "  -> key generated"
else
  ok "  -> key already exists"
fi

# ─── Step 2: Print pubkey for user to copy to GitHub ───
echo ""
log "Step 2: ADD THIS PUBKEY TO GITHUB (so the private key is authorized):"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "${KEY_PATH}.pub"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Pick one:"
echo "  - Account-level: https://github.com/settings/keys  (New SSH key)"
echo "  - Repo-only:     https://github.com/s0lut1on/vuihoc/settings/keys/new"
echo "                     (Allow write access: UNCHECKED)"
echo ""
warn "Bash will wait 30s for you to add it before continuing..."
warn "  Press ENTER if you've already added it. Ctrl-C to abort."
echo ""
read -t 30 -r -p "Press ENTER when done (or wait 30s): " || warn "Timeout - continuing anyway"

# ─── Step 3: Make sure your laptop can SSH to VPS ──────
log "Step 3: verify laptop->VPS SSH works..."
if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "$VPS_HOST" true 2>/dev/null; then
  err "Cannot SSH to $VPS_HOST with your current keys."
  err "Fix: ssh-copy-id -i ~/.ssh/your_main_key.pub $VPS_HOST"
  err "     (your 'main' key, NOT math_app_deploy - that's for git only)"
  exit 1
fi
ok "  -> laptop->VPS SSH works"

# ─── Step 4: SCP private key to VPS ────────────────────
log "Step 4: push private key to $VPS_HOST:/root/.ssh/math_app_deploy..."
ssh "$VPS_HOST" "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
scp "$KEY_PATH" "${VPS_HOST}:/root/.ssh/math_app_deploy"
ok "  -> pushed"

# ─── Step 5: Lock down perms on VPS ────────────────────
log "Step 5: chmod 600 on VPS..."
ssh "$VPS_HOST" "chmod 600 /root/.ssh/math_app_deploy && ls -la /root/.ssh/math_app_deploy"
ok "  -> perms set"

# ─── Step 6: Test git auth from VPS ────────────────────
log "Step 6: test 'ssh -T git@github.com' from VPS..."
out=$(ssh "$VPS_HOST" "ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1" || true)
echo "  -> output: $out"

if echo "$out" | grep -q "successfully authenticated\|You've been authenticated"; then
  ok "  ✅ VPS can now auth to GitHub - bootstrap will succeed"
  echo ""
  log "Next steps on the VPS:"
  echo "  ssh $VPS_HOST"
  echo "  bash scripts/vps-bootstrap.sh"
  echo "  cd /root/math-app/math-app && bash scripts/deploy-local.sh"
elif echo "$out" | grep -q "Permission denied (publickey)"; then
  err "  ❌ Still denied. The pubkey from step 2 wasn't added to GitHub."
  err "  -> Add it now: xclip -sel clip < ${KEY_PATH}.pub"
  err "  -> Then: https://github.com/settings/keys -> New SSH key -> paste"
  err "  -> Then re-run this script (step 6 only)"
  exit 2
else
  warn "  Unclear output - see above. Verify manually: ssh $VPS_HOST 'ssh -T git@github.com'"
fi
