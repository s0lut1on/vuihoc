#!/usr/bin/env bash
# Walk the user through paste-pubkey-into-GitHub-and-retry, end to end.
# Designed to fail loudly at the first sign of trouble.

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $*"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARN${NC} $*"; }
err()  { echo -e "${RED}[$(date +'%H:%M:%S')] ERR${NC} $*" >&2; }
ok()   { echo -e "${GREEN}[$(date +'%H:%M:%S')] OK${NC} $*"; }

VPS_HOST="${VPS_HOST:-root@194.233.94.167}"
KEY_PATH="${KEY_PATH:-/root/.ssh/math_app_deploy}"

# Step 1: Confirm laptop->VPS SSH
log "=== Step 1: confirm laptop->VPS SSH ==="
if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "$VPS_HOST" true 2>/dev/null; then
  err "Cannot SSH to $VPS_HOST"
  err "Fix: ssh-copy-id -i ~/.ssh/your_main_key.pub $VPS_HOST"
  exit 1
fi
ok "OK"

# Step 2: Read the VPS pubkey
log "=== Step 2: read the actual pubkey the VPS has ==="
PUBKEY=$(ssh -o BatchMode=yes "$VPS_HOST" "ssh-keygen -y -f $KEY_PATH" 2>&1 | tail -1)
FINGERPRINT=$(ssh -o BatchMode=yes "$VPS_HOST" "ssh-keygen -lf $KEY_PATH" 2>&1 | tail -1)

if [[ -z "$PUBKEY" ]] || [[ "$PUBKEY" == *"No such file"* ]]; then
  err "Cannot read private key at $KEY_PATH on VPS"
  err "Fix: scp ~/.ssh/math_app_deploy $VPS_HOST:/root/.ssh/math_app_deploy"
  exit 2
fi

echo ""
echo "  VPS pubkey:"
echo "    $PUBKEY"
echo ""
echo "  VPS fingerprint:"
echo "    $FINGERPRINT"
echo ""

# Step 3: Ask user to verify GitHub
log "=== Step 3: verify GitHub has THIS exact pubkey ==="
echo ""
echo "  Open https://github.com/settings/keys"
echo ""
echo "  For the key titled 'vps-deploy' (or whichever key you want to use for VPS):"
echo "    The SHA256 fingerprint MUST be: $FINGERPRINT"
echo ""
echo "  If they don't match, GitHub has a DIFFERENT key:"
echo "    1. Click 'Delete' on the old one"
echo "    2. Click 'New SSH key'"
echo "    3. Title: vps-deploy"
echo "    4. Paste this EXACT line (including the trailing 'vps-deploy' comment):"
echo ""
echo "       $PUBKEY"
echo ""
echo "  5. Click 'Add SSH key'"
echo ""
read -t 60 -r -p "Press ENTER when GitHub has the right key (or Ctrl-C to abort): " || \
  { err "Timed out - assuming you did it. Continuing to test in 5s..."; sleep 5; }

# Step 4: Re-test
log "=== Step 4: test ssh -T git@github.com from VPS ==="
out=$(ssh -o BatchMode=yes "$VPS_HOST" "ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -T git@github.com" 2>&1 || true)
echo "  Output: $out"
echo ""

if echo "$out" | grep -q "successfully authenticated"; then
  ok "GitHub accepted the key - VPS can now clone the private repo"
  echo ""
  log "Next steps on the VPS:"
  echo "  ssh $VPS_HOST"
  echo "  bash scripts/vps-bootstrap.sh"
  echo "  cd /root/math-app/math-app && bash scripts/deploy-local.sh"
  echo "  ufw enable"
  exit 0
fi

err "Still denied. Verbose log:"
ssh -o BatchMode=yes "$VPS_HOST" "ssh -vvv -o BatchMode=yes -o StrictHostKeyChecking=accept-new -T git@github.com" 2>&1 \
  | grep -iE 'offering|authentication|succeeded|permission|denied|publickey|loaded|identity' \
  | head -30
echo ""

# Diagnose based on verbose output
out2=$(ssh -o BatchMode=yes "$VPS_HOST" "ssh -vvv -o BatchMode=yes -o StrictHostKeyChecking=accept-new -T git@github.com" 2>&1 || true)
if echo "$out2" | grep -q "Offering ED25519 key" && echo "$out2" | grep -q "Permission denied"; then
  err "VPS IS offering the key, but GitHub rejected it."
  err "-> The pubkey registered on GitHub does NOT match the VPS private key."
  err "-> Re-check steps 2-3. Look for: trailing spaces, line wrap, "
  err "  copying from a terminal that broke the line, or pasting into"
  err "  the wrong GitHub account."
elif ! echo "$out2" | grep -q "Offering"; then
  err "ssh did NOT offer any key - VPS-side problem."
  err "-> Try: ssh $VPS_HOST 'chmod 600 $KEY_PATH && chmod 700 /root/.ssh'"
  err "-> Then re-run this script."
else
  err "Unexpected output. See verbose log above."
fi
exit 3
