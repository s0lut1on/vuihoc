#!/usr/bin/env bash
# Diagnose why 'ssh -T git@github.com' still fails on the VPS.
# Run FROM YOUR LAPTOP — it SSHes into the VPS to check everything.

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $*"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARN${NC} $*"; }
err()  { echo -e "${RED}[$(date +'%H:%M:%S')] ERR${NC} $*" >&2; }
ok()   { echo -e "${GREEN}[$(date +'%H:%M:%S')] OK${NC} $*"; }

VPS_HOST="${VPS_HOST:-root@sekklings.com}"
KEY_PATH="${KEY_PATH:-/root/.ssh/math_app_deploy}"

# Step 0: Verify we can reach the VPS
log "=== Step 0: Verify laptop→VPS SSH ==="
if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "$VPS_HOST" true 2>/dev/null; then
  err "Cannot SSH to $VPS_HOST from your laptop."
  err "Fix: ssh-copy-id -i ~/.ssh/your_main_key.pub $VPS_HOST"
  exit 1
fi
ok "Laptop can SSH to $VPS_HOST"
echo ""

# Step 1: Private key exists?
log "=== Step 1: Does the private key exist on the VPS? ==="
ssh "$VPS_HOST" "ls -la $KEY_PATH 2>&1 || echo 'MISSING: $KEY_PATH does not exist on VPS'"
echo ""

# Step 2: Perms correct?
log "=== Step 2: Perms of the private key (ssh requires 600) ==="
ssh "$VPS_HOST" "stat -c '%a %n' $KEY_PATH 2>&1 || echo 'no key'"
PERMS=$(ssh "$VPS_HOST" "stat -c '%a' $KEY_PATH 2>/dev/null" || echo "")
if [[ -n "$PERMS" ]] && [[ "$PERMS" != "600" ]] && [[ "$PERMS" != "400" ]]; then
  warn "  Perms are $PERMS — ssh REQUIRES 600 or stricter"
  warn "  Fix: ssh $VPS_HOST 'chmod 600 $KEY_PATH'"
fi
echo ""

# Step 3: ~/.ssh dir perms (must be 700)
log "=== Step 3: /root/.ssh perms (must be 700) ==="
ssh "$VPS_HOST" "stat -c '%a %n' /root/.ssh 2>&1 || echo 'no /root/.ssh'"
SSHDIR=$(ssh "$VPS_HOST" "stat -c '%a' /root/.ssh 2>/dev/null" || echo "")
if [[ "$SSHDIR" != "700" ]] && [[ "$SSHDIR" != "755" ]]; then
  warn "  /root/.ssh perms are $SSHDIR — ssh REQUIRES 700"
  warn "  Fix: ssh $VPS_HOST 'chmod 700 /root/.ssh'"
fi
echo ""

# Step 4: Show the pubkey + its fingerprint as the VPS sees it
log "=== Step 4: Pubkey that VPS would use + its fingerprint ==="
ssh "$VPS_HOST" "test -f $KEY_PATH.pub && cat $KEY_PATH.pub || echo '(no .pub file on VPS)'"
echo ""
ssh "$VPS_HOST" "ssh-keygen -lf $KEY_PATH 2>&1 || true"
echo ""
warn "  Compare the fingerprint above to what's listed at:"
warn "    https://github.com/settings/keys"
warn "  If they don't match, the pubkey registered on GitHub is from a"
warn "  DIFFERENT key pair. Re-add the pubkey from step 4."
echo ""

# Step 5: Test ssh with verbose to see which keys it offers
log "=== Step 5: Verbose SSH to see which keys the VPS tries ==="
ssh "$VPS_HOST" "ssh -vvv -T -o StrictHostKeyChecking=accept-new git@github.com 2>&1 | grep -E 'Offering|Authentication|succeeded|Permission denied|authenticated|publickey' | head -20" || true
echo ""

# Step 6: Test as if we were git (BatchMode = no prompts)
log "=== Step 6: Final test (BatchMode = no prompts) ==="
out=$(ssh "$VPS_HOST" "ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1" || true)
echo "  Output: $out"
if echo "$out" | grep -q "successfully authenticated\|You've been authenticated"; then
  ok "✅ VPS can now auth to GitHub — bootstrap will succeed"
else
  err "❌ Still denied. Common fixes:"
  err "  1. Wrong perms on key: ssh $VPS_HOST 'chmod 600 $KEY_PATH && chmod 700 /root/.ssh'"
  err "  2. Wrong key on GitHub: re-add the pubkey shown in step 4"
  err "  3. ssh-agent not using it: ssh $VPS_HOST 'eval \$(ssh-agent) && ssh-add $KEY_PATH'"
  err "  4. Known hosts missing: ssh $VPS_HOST 'ssh-keyscan github.com >> ~/.ssh/known_hosts'"
fi
